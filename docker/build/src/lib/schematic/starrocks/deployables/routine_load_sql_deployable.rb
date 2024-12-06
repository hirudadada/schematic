# frozen_string_literal: true

require_relative 'strategies'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadSqlDeployable < SqlDeployable
        include Defaults

        ALLOWED_SQL_PATTERNS = [
          /\ACREATE\s+ROUTINE\s+LOAD\s+(?:`?(?<db_name>[^`\s.]+)`?\.)?`?(?<routine_name>[^`\s.]+)`?\s+ON\s+`?(?<table_name>[^`\s.]+)`?/i,
          /\s+COLUMNS\s*\([^)]+\)/i,
          /\s+PROPERTIES\s*\([^)]+\)/i
        ].freeze

        ALLOWED_COMMANDS = [
          /\AUSE\s+[^;\s]+/i,
          /\ACREATE\s+ROUTINE\s+LOAD\s+(?:`?(?<db_name>[^`\s.]+)`?\.)?`?(?<routine_name>[^`\s.]+)`?\s+ON\s+`?(?<table_name>[^`\s.]+)`?/i,
          /\APAUSE\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?(?<db_name>[^`\s.]+)`?)?\s+FOR\s+`?(?<routine_name>[^`\s.]+)`?/i,
          /\ARESUME\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?(?<db_name>[^`\s.]+)`?)?\s+FOR\s+`?(?<routine_name>[^`\s.]+)`?/i,
          /\ASTOP\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?(?<db_name>[^`\s.]+)`?)?\s+FOR\s+`?(?<routine_name>[^`\s.]+)`?/i,
          /\AALTER\s+ROUTINE\s+LOAD(?:\s+FROM\s+`?(?<db_name>[^`\s.]+)`?)?\s+FOR\s+`?(?<routine_name>[^`\s.]+)`?/i
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
        end

        protected

        # These methods must be implemented by subclasses
        def parse_statements(sql)
          raise NotImplementedError
        end

        def validate_statements!(statements)
          raise NotImplementedError
        end

        def extract_create_statement(statements)
          raise NotImplementedError
        end

        def extract_load_info(statement)
          raise NotImplementedError
        end

        def has_create_statement?(statements)
          raise NotImplementedError
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
    end
  end
end
