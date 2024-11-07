# frozen_string_literal: true

require_relative '../templates/naming'
require_relative 'strategies/routine_load_deployment_strategy'
require_relative 'strategies/auto_stop_strategy'
require_relative 'strategies/user_defined_strategy'
require_relative 'strategies/migration_strategy'

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        def self.create(type, options = {})
          case type
          when :migration
            MigrationStrategy.new(options)
          when :auto_stop
            AutoStopStrategy.new(options)
          when :user_defined
            UserDefinedStrategy.new(options)
          else
            RoutineLoadDeploymentStrategy.new(options)
          end
        end
      end
    end
  end
end