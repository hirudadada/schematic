# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class DeployableResource
        attr_reader :name, :data, :options, :strategy

        BaseOptions = Types::Hash.schema(
          logger: Types.Instance(Logger).optional,
          log_level: Types::Coercible::Integer.optional,
          strategy: Types.Instance(Strategies::RoutineLoadDeploymentStrategy),
          migration_mode: Types::Strict::Bool.optional,
          provider: Types.Instance(Providers::RoutineLoadConfigProvider).optional
        ).with_key_transform(&:to_sym)

        def initialize(name, data, options = {})
          @name = Types::StrictString[name]
          @data = data  # Type checking happens in specific deployables
          @options = BaseOptions[options]
          @strategy = @options[:strategy]
        end

        def deploy(client)
          execute_deploy(client)
        end

        protected

        def execute_deploy(client)
          raise NotImplementedError, "#{self.class} must implement 'execute_deploy' method"
        end

        def logger
          @logger ||= init_logger
        end

        private

        def init_logger
          logger = options[:logger] || Logger.new($stdout)
          logger.level = options[:log_level] || Logger::INFO
          logger
        end
      end
    end
  end
end
