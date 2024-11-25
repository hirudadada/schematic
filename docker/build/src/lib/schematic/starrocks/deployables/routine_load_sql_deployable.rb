# frozen_string_literal: true

require_relative 'strategies'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadSqlDeployable < SqlDeployable
        include Defaults

        module DeploymentMethods
          def parse_statements(sql)
            sql.split(';')
               .map(&:strip)
               .reject(&:empty?)
          end

          def extract_create_statement(statements)
            create_stmt = statements.find { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
            raise Schematic::Starrocks::RoutineLoadError, "No CREATE ROUTINE LOAD statement found" unless create_stmt
            Types::StrictString[create_stmt]
          end

          def extract_load_info(sql)
            operation = case sql
                        when /\ACREATE\s+ROUTINE\s+LOAD/i then 'create'
                        when /\APAUSE\s+ROUTINE\s+LOAD/i then 'pause'
                        when /\ARESUME\s+ROUTINE\s+LOAD/i then 'resume'
                        when /\ASTOP\s+ROUTINE\s+LOAD/i then 'stop'
                        when /\AALTER\s+ROUTINE\s+LOAD/i then 'alter'
                        else ''
                        end

            version = name.split('-').first

            if sql.match?(/\ACREATE\s+ROUTINE\s+LOAD/i)
              match = ALLOWED_SQL_PATTERNS.first.match(sql)
              raise Schematic::Starrocks::ValidationError, "Cannot extract routine load info from CREATE SQL" unless match

              Types::RoutineLoadInfo[{
                db_name: options[:provider]&.db_name || 'schematic',
                routine_name: match[:routine_name],
                operation: operation,
                table_name: match[:table_name],
                version: version
              }]
            else
              match = /FOR\s+`?(?<routine_name>[^`\s]+)`?/i.match(sql)
              raise Schematic::Starrocks::ValidationError, "Cannot extract routine load info from SQL" unless match
              
              table_name = match[:routine_name].sub(/_rl$/, '')
              
              Types::RoutineLoadInfo[{
                db_name: options[:provider]&.db_name || 'schematic',
                routine_name: match[:routine_name],
                operation: operation,
                table_name: table_name,
                version: version
              }]
            end
          end

          def validate_statements!(statements)
            statements.each do |stmt|
              unless ALLOWED_COMMANDS.any? { |pattern| stmt.match?(pattern) }
                raise Schematic::Starrocks::ValidationError, "Invalid routine load command: #{stmt}"
              end

              if stmt.match?(/FROM\s+`([^`]+)`/i)
                db_name = $1
                unless db_name == options[:provider]&.db_name
                  raise Schematic::Starrocks::ValidationError, "Cannot access database: #{db_name}"
                end
              end
            end

            if has_create_statement?(statements)
              validate_create_statement!(extract_create_statement(statements))
            end
          end

          def validate_create_statement!(create_stmt)
            FORBIDDEN_PATTERNS.each do |pattern|
              if create_stmt.match?(pattern)
                raise Schematic::Starrocks::ValidationError, "SQL contains forbidden pattern: #{pattern.source}"
              end
            end

            ALLOWED_SQL_PATTERNS.each do |pattern|
              unless create_stmt.match?(pattern)
                raise Schematic::Starrocks::ValidationError, "SQL must contain required pattern: #{pattern.source}"
              end
            end
          end

          def has_create_statement?(statements)
            statements.any? { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
          end

          def log_command_execution(stmt)
            case stmt
            when /\APAUSE/i
              logger.info("Paused routine load")
            when /\ARESUME/i
              logger.info("Resumed routine load")
            when /\ASTOP/i
              logger.info("Stopped routine load")
            when /\AALTER/i
              logger.info("Altered routine load")
            end
          end
        end

        include DeploymentMethods

        ALLOWED_SQL_PATTERNS = [
          /\ACREATE\s+ROUTINE\s+LOAD\s+(?:`?[^`\s]+`?\.)?`?(?<routine_name>[^`\s]+)`?\s+ON\s+`?(?<table_name>[^`\s]+)`?/i,
          /\s+COLUMNS\s*\([^)]+\)/i,
          /\s+PROPERTIES\s*\([^)]+\)/i
        ].freeze

        ALLOWED_COMMANDS = [
          /\AUSE\s+[^;\s]+/i,
          /\ACREATE\s+ROUTINE\s+LOAD\s+(?:`?[^`\s]+`?\.)?`?(?<routine_name>[^`\s]+)`?\s+ON\s+`?(?<table_name>[^`\s]+)`?/i,
          /\APAUSE\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?[^`\s]+`?)?(?:\s+FOR\s+`?(?<routine_name>[^`\s]+)`?)/i,
          /\ARESUME\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?[^`\s]+`?)?(?:\s+FOR\s+`?(?<routine_name>[^`\s]+)`?)/i,
          /\ASTOP\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?[^`\s]+`?)?(?:\s+FOR\s+`?(?<routine_name>[^`\s]+)`?)/i,
          /\AALTER\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?[^`\s]+`?)?(?:\s+FOR\s+`?(?<routine_name>[^`\s]+)`?)/i
        ].freeze

        FORBIDDEN_PATTERNS = [
          /\/\*/,
          /xp_/i,
          /EXEC\s+/i,
          /EXECUTE\s+/i,
          /UNION/i,
          /INTO\s+/i,
          /DROP\s+/i,
          /DELETE\s+/i,
          /UPDATE\s+/i
        ].freeze

        def deploy(client)
          client.transaction do
            statements = parse_statements(data)
            validate_statements!(statements)

            load_info = if has_create_statement?(statements)
                          create_stmt = extract_create_statement(statements)
                          extract_load_info(create_stmt)
                        else
                          extract_load_info(statements.first)
                        end

            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, statements, load_info)
          end
          logger.info("Deployed #{name}")
        end

        def validate_sql_syntax!
          sql = data.to_s.strip
          raise Schematic::Starrocks::ValidationError, 'SQL statement cannot be empty' if sql.empty?
          raise Schematic::Starrocks::ValidationError, 'SQL statement is too long' if sql.length > 10000

          statements = parse_statements(sql)
          validate_statements!(statements)
        end
      end
    end
  end
end
