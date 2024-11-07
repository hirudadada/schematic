# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class AutoStopStrategy < RoutineLoadDeploymentStrategy
          # LoadInfo = Types::Hash.schema(
          #   db_name: Types::StrictString,
          #   routine_name: Types::StrictString.constrained(format: /\Arl_[\w]+\z/)
          # )
          #
          def execute(client, statements, load_info)
            load_info = Types::RoutineLoadInfo[load_info]
            
            check_and_stop_existing(client, load_info[:db_name], load_info[:routine_name])
            statements.each { |stmt| execute_with_delay(client, stmt) }
          end

          private

          def check_and_stop_existing(client, db_name, load_name)
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{load_name}'").all

            if result.any?
              stop_sql = "STOP ROUTINE LOAD FOR `#{load_name}`"
              logger.debug("Stopping existing routine load: #{stop_sql}") if logger.debug?
              client.run(stop_sql)
              sleep(2)
            end
          end
        end
      end
    end
  end
end
