# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateRoutineLoadRbDeployable < CreateRoutineLoadSqlDeployable
        attr_reader :name, :data

        def initialize(name, data)
          super
          validate
        end

        def sql
          data[:sql]
        end

        protected

        def validate
          unless data.is_a?(Hash) && data[:name] && data[:task] && data[:sql]
            raise ArgumentError, "Invalid data format for #{self.class.name}: #{data.inspect}"
          end

          unless task == :create_routine_load
            raise ArgumentError, "Unsupported task '#{data[:task]}' for #{self.class.name}"
          end

          # You can add more validation rules here as needed
        end
      end
    end
  end
end
