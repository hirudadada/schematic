# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class UserDefinedStrategy < RoutineLoadDeploymentStrategy
          def execute(client, statements, load_info)
            load_info = Types::RoutineLoadInfo[load_info]
            statements.each { |stmt| execute_with_delay(client, stmt) }
          end
        end
      end
    end
  end
end
