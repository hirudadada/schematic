# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class CreateRoutineLoadConfigTemplate < JsonTemplate
        def initialize
          super(:create_materialized_view)
        end

        def create
          ROUTINE_LOAD_CONFIG
        end
      end
    end
  end
end
