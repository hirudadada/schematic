# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployable
      class DeployableResourceRepository
        def initialize
          @resource = {}
        end

        def register(task, type, klass)
          @resources[task] ||= {}
          @resources[task][type] = klass
        end

        def get(task, type)
          @resources.dig(task, type) || raise(KeyError, "No resource found for task: #{task}, type: #{type}")
        end

        def create(task:, type:, name:, data:)
          klass = get(task, type)
          klass.new(name: name, data: data)
        end
      end
    end
  end
end

