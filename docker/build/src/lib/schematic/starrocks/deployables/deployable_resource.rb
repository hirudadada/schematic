# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class DeployableResource
        attr_reader :name, :data, :options

        def initialize(name, data, options = {})
          @name = name
          @data = data
          @options = options
        end

        def deploy(client)
          raise NotImplementedError, "#{self.class} must implement 'deploy' method"
        end

        def logger
          @logger ||= init_logger
        end

        protected

        def init_logger
          logger = options[:logger] || Logger.new($stdout)
          logger.level = options[:log_level] || Logger::INFO
          logger
        end
      end
    end
  end
end
