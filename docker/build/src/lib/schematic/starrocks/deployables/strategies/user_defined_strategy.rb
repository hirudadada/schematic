# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class UserDefinedStopStrategy < RoutineLoadDeploymentStrategy
          def execute(client, statements, _load_info)
            statements.each do |stmt|
              execute_with_delay(client, stmt)
            end
          end
        end
      end
    end
  end
end