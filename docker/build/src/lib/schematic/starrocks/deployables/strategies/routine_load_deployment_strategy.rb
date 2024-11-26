# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class RoutineLoadDeploymentStrategy
          include Concerns::Retryable
          
          attr_reader :options, :name, :load_info

          def initialize(options = {}, name = nil)
            @options = options
            @name = name
          end

          def execute(client, statements, load_info)
            @load_info = Types::RoutineLoadInfo[load_info]
            @client = client
            
            if should_auto_stop?(statements)
              check_and_stop_existing(client, @load_info[:db_name], @load_info[:routine_name])
            end
            
            statements.each do |stmt|
              execute_with_delay(client, stmt)
            end
          end

          private

          def check_and_stop_existing(client, db_name, routine_name)
            db_name = Types::StrictString[db_name]
            routine_name = Types::StrictString[routine_name]
            
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{routine_name}'").all
            
            if result.any?
              stop_sql = "STOP ROUTINE LOAD FOR `#{routine_name}`"
              logger.debug("Checking existing routine load: #{stop_sql}")
              execute_with_retry { client.run(stop_sql) }
            end
          end

          def execute_with_delay(client, stmt)
            execute_with_retry { client.run(stmt) }
          end

          def should_auto_stop?(statements)
            statements.any? { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
          end

          def logger
            @logger ||= options[:logger] || Logger.new($stdout)
          end
        end
      end
    end
  end
end
