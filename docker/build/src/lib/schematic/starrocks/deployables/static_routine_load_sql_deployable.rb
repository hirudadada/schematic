module Schematic
  module Starrocks
    module Deployables
      class StaticRoutineLoadSqlDeployable < RoutineLoadSqlDeployable
        def parse_statements(sql)
          sql.split(';').map(&:strip).reject(&:empty?)
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

        def extract_create_statement(statements)
          create_stmt = statements.find { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
          raise Schematic::Starrocks::RoutineLoadError, "No CREATE ROUTINE LOAD statement found" unless create_stmt
          Types::StrictString[create_stmt]
        end

        def extract_load_info(sql)
          logger.debug("Extracting load info from SQL: #{sql}")
          
          operation = case sql
                      when /\ACREATE\s+ROUTINE\s+LOAD/i then 'create'
                      when /\APAUSE\s+ROUTINE\s+LOAD/i then 'pause'
                      when /\ARESUME\s+ROUTINE\s+LOAD/i then 'resume'
                      when /\ASTOP\s+ROUTINE\s+LOAD/i then 'stop'
                      when /\AALTER\s+ROUTINE\s+LOAD/i then 'alter'
                      else ''
                      end
          logger.debug("Detected operation: #{operation}")

          version = name.split('-').first
          logger.debug("Version from filename: #{version}")
          
          db_name = if sql =~ /(?:FROM|CREATE\s+ROUTINE\s+LOAD)\s+[`"]?([^`"\s.]+)[`"]?\./i
                      logger.debug("Found db_name in SQL: #{$1}")
                      $1
                    else
                      provider_db = options[:provider]&.db_name
                      logger.debug("Using provider db_name: #{provider_db || 'schematic'}")
                      provider_db || 'schematic'
                    end

          routine_name = if sql =~ /(?:FOR|CREATE\s+ROUTINE\s+LOAD\s+(?:[^.]+\.)?)\s*[`"]?([^`"\s]+)[`"]?/i
                           logger.debug("Found routine_name in SQL: #{$1}")
                           $1
                         else
                           raise Schematic::Starrocks::ValidationError, "Cannot extract routine_name from SQL"
                         end

          table_name = if operation == 'create' && sql =~ /ON\s+[`"]?([^`"\s]+)[`"]?/i
                           logger.debug("Found table_name in SQL: #{$1}")
                           $1
                         else
                           name = routine_name.sub(/_rl$/, '')
                           logger.debug("Derived table_name from routine_name: #{name}")
                           name
                         end

          load_info = {
            db_name: db_name,
            routine_name: routine_name,
            operation: operation,
            table_name: table_name,
            version: version
          }
          logger.debug("Final load_info: #{load_info.inspect}")

          Types::RoutineLoadInfo[load_info]
        end


        def has_create_statement?(statements)
          statements.any? { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
        end

        private

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
      end
    end
  end
end 