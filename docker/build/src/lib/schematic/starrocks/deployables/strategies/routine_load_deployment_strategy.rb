# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class RoutineLoadDeploymentStrategy
          attr_reader :options

          def initialize(options = {})
            @options = options
          end

          def logger
            @logger ||= init_logger
          end

          def execute(client, statements, load_info)
            raise NotImplementedError, "#{self.class} must implement execute"
          end

          protected

          def execute_with_delay(client, stmt)
            logger.debug("Executing SQL statement: #{stmt}") if logger.debug?
            client.run(stmt)
            if stmt.match?(/\ASTOP\s+ROUTINE\s+LOAD/i)
              logger.debug("Waiting after STOP ROUTINE LOAD")
              sleep(2)
            end
          end

          def init_logger
            logger = options[:logger] || Logger.new($stdout)
            logger.level = options[:log_level] || Logger::INFO
            logger
          end
        end
      end
    end
  end
end 