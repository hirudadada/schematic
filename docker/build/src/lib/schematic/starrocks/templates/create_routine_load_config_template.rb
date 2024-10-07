# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class CreateRoutineLoadConfigTemplate < JsonTemplate
        def initialize(routine_name)
          super(routine_name, :create_routine_load)
        end

        def create
          config = RoutineLoadConfig.new(ROUTINE_LOAD_CONFIG)
          config.routine_name = name

          {
            name: name,
            task: task,
            config: config.to_hash
          }
        end
      end
    end
  end
end
