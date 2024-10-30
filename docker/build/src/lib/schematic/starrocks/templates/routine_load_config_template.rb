# frozen_string_literal: true

require 'yaml'
require_relative '../routine_load_config'

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadConfigTemplate < ConfigTemplate
        def initialize(routine_name, operation = :create)
          super(routine_name, :routine_load)
          @operation = operation
        end

        def create
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          config.operation = @operation.to_s

          case @operation
          when :create
            create_config(config)
          when :pause, :resume, :stop
            state_change_config(config)
          when :alter
            alter_config(config)
          else
            raise ArgumentError, "Unsupported operation: #{@operation}"
          end
        end

        private

        def create_config(config)
          config.to_yaml
        end

        def state_change_config(config)
          {
            name: name,
            db: config.db,
            routine_name: config.routine_name,
            operation: config.operation
          }.to_yaml
        end

        def alter_config(config)
          {
            name: name,
            db: config.db,
            routine_name: config.routine_name,
            operation: config.operation,
            properties: config.properties
          }.to_yaml
        end
      end
    end
  end
end 
