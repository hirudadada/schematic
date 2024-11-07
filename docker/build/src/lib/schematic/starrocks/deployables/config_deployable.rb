# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class ConfigDeployable < DeployableResource
        ConfigData = Types::Hash.schema(
          task: Types::StrictSymbol | Types::Coercible::Symbol,
          config: Types::Hash
        )

        def initialize(name, data, options = {})
          @data = ConfigData[data]  # Validate config data
          super(name, @data, options)
        end

        def task
          data[:task].to_sym
        end

        def config
          data[:config]
        end

        def deploy(client)
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end

