# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateMaterializedViewRbDeployable < CreateMaterializedViewSqlDeployable
        def initialize(name, data)
          super
          validate
        end

        def task = data[:task]

        def sql = data[:sql]

        private

        def validate
          unless data.is_a?(Hash) && data[:name] && data[:task] && (data[:sql] || data[:config])
            raise ArgumentError, "Invalid data format for #{self.class.name}: #{data.inspect}"
          end

          unless task == :create_materialized_view
            raise ArgumentError, "Unsupported task '#{data[:task]}' for #{self.class.name}"
          end
        end
      end
    end
  end
end
