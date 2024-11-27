module Schematic
  module Starrocks
    module Deployables
      module States
        class RoutineLoadState
          def self.get_state(client, db_name, routine_name)
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{routine_name}'").all.first
            
            # Handle both string and symbol keys
            state = if result
              result['State'] || result[:State]
            end
            
            {
              exists: !result.nil?,
              state: state,
              progress: result && (result['Progress'] || result[:Progress]),
              last_error: result && (result['LastError'] || result[:LastError]),
              created_time: result && (result['CreateTime'] || result[:CreateTime])
            }
          end
        end
      end
    end
  end
end 