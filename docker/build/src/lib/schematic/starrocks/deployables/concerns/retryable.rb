module Schematic
  module Starrocks
    module Deployables
      module Concerns
        module Retryable
          DEFAULT_MAX_RETRIES = 3
          DEFAULT_BASE_DELAY = 2 # seconds
          
          def execute_with_retry
            retries = 0
            max_retries = fetch_max_retries
            base_delay = fetch_base_delay
            
            begin
              logger.debug("Executing statement with retry (attempt #{retries + 1}/#{max_retries})")
              yield
              sleep(base_delay)
            rescue Mysql2::Error::ConnectionError => e
              handle_connection_error(e, retries, max_retries, base_delay)
            rescue StandardError => e
              if e.message.include?('Could not transform')
                handle_state_transformation_error(e)
              elsif e.is_a?(Mysql2::Error)
                handle_mysql_error(e)
              else
                raise
              end
            end
          end

          private

          def handle_connection_error(error, retries, max_retries, base_delay)
            retries += 1
            if retries <= max_retries
              delay = base_delay * retries
              logger.warn("Connection lost, retrying in #{delay}s (attempt #{retries}/#{max_retries})")
              sleep(delay)
              raise Sequel::DatabaseDisconnectError.new(error.message)
            end
            logger.error("Max retries exceeded (#{max_retries})")
            raise Schematic::Starrocks::ConnectionError.new(
              "Max retries (#{max_retries}) exceeded: #{error.message}",
              retries
            )
          end

          def handle_state_transformation_error(error)
            current_state = get_current_state
            desired_state = extract_desired_state_from_error(error.message)
            
            if current_state && desired_state_matches?(current_state, desired_state)
              logger.info("Already in desired state: #{current_state}")
              return
            end
            
            logger.error("State transformation error: #{current_state} -> #{desired_state}")
            raise Schematic::Starrocks::StateTransformationError.new(
              current_state,
              desired_state,
              error.message
            )
          end

          def handle_mysql_error(error)
            case error.message
            when /Routine load .* does not exist/
              logger.error("Routine load not found: #{error.message}")
              raise Schematic::Starrocks::RoutineLoadError, 
                "Routine load not found: #{error.message}"
            else
              logger.error("Database error: #{error.message}")
              raise Schematic::Starrocks::Error, 
                "Database error: #{error.message}"
            end
          end

          def get_current_state
            return unless defined?(@load_info) && @load_info
            
            state = States::RoutineLoadState.get_state(
              @client, 
              @load_info[:db_name], 
              @load_info[:routine_name]
            )
            state[:state]
          end

          def extract_desired_state_from_error(message)
            if message =~ /Could not transform (\w+) to (\w+)/
              $2 # Second capture is the desired state
            else
              'UNKNOWN'
            end
          end

          def desired_state_matches?(current_state, desired_state)
            case desired_state
            when 'PAUSED' then current_state == 'PAUSED'
            when 'RUNNING' then current_state == 'RUNNING'
            when 'STOPPED' then current_state == 'STOPPED'
            else false
            end
          end

          def fetch_max_retries
            ENV.fetch('RETRY_MAX_ATTEMPTS', DEFAULT_MAX_RETRIES).to_i
          end

          def fetch_base_delay
            ENV.fetch('RETRY_BASE_DELAY', DEFAULT_BASE_DELAY).to_i
          end
        end
      end
    end
  end
end 