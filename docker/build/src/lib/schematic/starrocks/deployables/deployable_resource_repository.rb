# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class DeployableResourceRepository
        attr_reader :resources

        def initialize
          @resources = {}
        end

        def register(task, type, klass)
          @resources[task] ||= {}
          @resources[task][type] = klass
        end

        def get(task, type)
          @resources.dig(task, type) || raise(KeyError, "No resource found for task: #{task}, type: #{type}")
        end

        def create(task:, type:, name:, data:, **options)
          klass = get(task, type)
          klass.new(name, data, options)
        end
      end
    end
  end
end

