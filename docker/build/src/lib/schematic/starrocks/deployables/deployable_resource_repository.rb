# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class DeployableResourceRepository
        attr_reader :resources

        ResourceTypes = Types::Hash.schema(
          task: Types::StrictSymbol,
          type: Types::StrictSymbol,
          name: Types::StrictString,
          data: Types::Any,
          options: Types::Hash.optional.default({}, shared: true)
        ).with_key_transform(&:to_sym)

        def initialize
          @resources = {}
        end

        def register(task, type, klass)
          task = Types::StrictSymbol[task]
          type = Types::StrictSymbol[type]
          
          @resources[task] ||= {}
          @resources[task][type] = klass
        end

        def get(task, type)
          task = Types::StrictSymbol[task]
          type = Types::StrictSymbol[type]
          
          @resources.dig(task, type) || raise(KeyError, "No resource found for task: #{task}, type: #{type}")
        end

        def create(task:, type:, name:, data:, **options)
          params = ResourceTypes[{
            task: task,
            type: type,
            name: name,
            data: data,
            options: options
          }]
          
          klass = get(params[:task], params[:type])
          
          # Set strategy based on migration mode and operation type
          if params[:task] == :routine_load
            if params[:options][:migration_mode]
              params[:options][:strategy] = Strategies::MigrationStrategy.new(params[:options], params[:name])
            else
              params[:options][:strategy] = Strategies::RoutineLoadDeploymentStrategy.new(params[:options],params[:name])
            end
          end
          
          klass.new(params[:name], params[:data], params[:options])
        end
      end
    end
  end
end

