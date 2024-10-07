# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class DeployableResource
        attr_reader :name, :data

        def initialize(name, data)
          @name = name
          @data = data
        end

        def deploy(client)
          raise NotImplementedError, "#{self.class} must implement 'deploy' method"
        end
      end
    end
  end
end
