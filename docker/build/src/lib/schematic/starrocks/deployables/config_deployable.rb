# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class ConfigDeployable < DeployableResource
        def initialize(name, data, options = {})
          super(name, data, options)
        end

        def deploy(client)
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end

