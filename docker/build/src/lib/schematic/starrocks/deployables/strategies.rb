# frozen_string_literal: true

require_relative '../templates/naming'
require_relative 'strategies/routine_load_deployment_strategy'
require_relative 'strategies/migration_strategy'

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        def self.create(options = {})
          if options[:migration_mode]
            MigrationStrategy.new(options)
          else
            RoutineLoadDeploymentStrategy.new(options)
          end
        end
      end
    end
  end
end