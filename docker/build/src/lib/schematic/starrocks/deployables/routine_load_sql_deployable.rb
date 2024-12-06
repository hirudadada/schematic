# frozen_string_literal: true

require_relative 'strategies'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadSqlDeployable < SqlDeployable
        include Defaults

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
