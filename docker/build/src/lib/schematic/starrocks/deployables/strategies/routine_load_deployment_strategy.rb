# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class RoutineLoadDeploymentStrategy
          attr_reader :options, :name, :load_info

          def initialize(options = {}, name = nil)
            @options = options
            @name = name
            @migration_mode = options[:migration_mode]
          end

          def execute(client, statements, load_info)
            @load_info = Types::RoutineLoadInfo[load_info]
            
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
              client.run(stop_sql)
              sleep(2)
            end
          end

          def execute_with_delay(client, stmt)
            retries = 0
            max_retries = 3
            
            begin
              client.run(stmt)
              sleep(2)
            rescue Mysql2::Error::ConnectionError => e
              handle_connection_error(e, retries, max_retries)
            rescue StandardError => e
              if e.message.include?('Could not transform')
                handle_mysql_error(e, client, stmt)
              elsif e.is_a?(Mysql2::Error)
                handle_mysql_error(e, client, stmt)
              else
                raise
              end
            end
          end

          def handle_connection_error(error, retries, max_retries)
            retries += 1
            if retries <= max_retries
              sleep(2 * retries)
              raise Sequel::DatabaseDisconnectError.new(error.message)
            end
            raise Schematic::Starrocks::ConnectionError.new(
              "Max retries (#{max_retries}) exceeded: #{error.message}",
              retries
            )
          end

          def handle_mysql_error(error, client, stmt)
            case error.message
            when /Could not transform/
              handle_state_transformation_error(client, stmt)
            when /Routine load .* does not exist/
              raise Schematic::Starrocks::RoutineLoadError, 
                "Routine load not found: #{error.message}"
            else
              raise Schematic::Starrocks::Error, 
                "Database error: #{error.message}"
            end
          end

          def handle_state_transformation_error(client, stmt)
            state = States::RoutineLoadState.get_state(
              client, 
              load_info[:db_name], 
              load_info[:routine_name]
            )
            
            current_state = state[:state] || 'UNKNOWN'
            desired_state = extract_desired_state(stmt)
            
            if state[:exists] && desired_state_matches?(stmt, current_state)
              return
            end
            
            raise Schematic::Starrocks::StateTransformationError.new(
              current_state,
              desired_state
            )
          end

          def extract_desired_state(stmt)
            case stmt
            when /PAUSE/ then 'PAUSED'
            when /RESUME/ then 'RUNNING'
            when /STOP/ then 'STOPPED'
            else 'UNKNOWN'
            end
          end

          def should_auto_stop?(statements)
            statements.any? { |stmt| stmt.match?(/\ACREATE\s+ROUTINE\s+LOAD/i) }
          end

          def desired_state_matches?(stmt, current_state)
            case stmt
            when /PAUSE/ then current_state == 'PAUSED'
            when /RESUME/ then current_state == 'RUNNING'
            when /STOP/ then current_state == 'STOPPED'
            else false
            end
          end

          def logger
            @logger ||= options[:logger] || Logger.new($stdout)
          end
        end
      end
    end
  end
end