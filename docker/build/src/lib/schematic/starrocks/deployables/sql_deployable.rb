# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class SqlDeployable < DeployableResource
        SqlData = Types::Strict::String | Types::Strict::Array.of(Types::Strict::String)

        def initialize(name, data, options = {})
          @data = SqlData[data]  # Validate SQL data
          super(name, @data, options)
        end

        def sql
          data
        end

        def deploy(client)
          logger.debug("Executing SQL: #{sql}") if logger.debug?
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end

