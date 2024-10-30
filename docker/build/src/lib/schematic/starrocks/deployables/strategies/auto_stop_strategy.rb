# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class AutoStopStrategy < RoutineLoadDeploymentStrategy
          def execute(client, statements, load_info)
            check_and_stop_existing(client, load_info[:db_name], load_info[:load_name])
            statements.each do |stmt|
              execute_with_delay(client, stmt)
            end
          end

          private

          def check_and_stop_existing(client, db_name, load_name)
            show_sql = "SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{load_name}'"
            logger.debug("Checking existing routine load: #{show_sql}") if logger.debug?
            result = client.fetch(show_sql).all
            
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