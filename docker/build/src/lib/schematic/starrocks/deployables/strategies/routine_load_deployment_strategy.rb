# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class RoutineLoadDeploymentStrategy
          attr_reader :options, :name

          def initialize(options = {}, name = nil)
            @options = options
            @name = name
            @migration_mode = options[:migration_mode]
          end

          def execute(client, statements, load_info)
            raise NotImplementedError, "#{self.class} must implement 'execute' method"
          end

          protected

          def execute_with_delay(client, stmt)
            logger.debug("Executing routine load command: #{stmt}") if logger.debug?
            client.run(stmt)
            sleep(2)
          end

          def logger
            @logger ||= options[:logger] || Logger.new($stdout)
          end
        end
      end
    end
  end
end 