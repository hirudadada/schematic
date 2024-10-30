# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    class Deployment
      attr_reader :deployer, :resource_repo, :options

      def initialize(deployer, resource_repo, opts = {})
        @options = opts
        yield @options if block_given?
        @deployer = deployer
        @resource_repo = resource_repo
        register_resource_classes
      end

      def deploy_all(resource_types = nil)
        deploy_resource_types(resource_types)
      end

      protected

      def deploy_resource_types(resource_types = nil)
        resource_types_to_deploy = resource_types || self.resource_types
        resource_types_to_deploy.each do |resource_type|
          deploy_resources(resource_dir(resource_type), resource_task(resource_type))
        end
      end

      def deploy_resources(dir, task)
        Dir.glob(File.join(dir, '*')).sort.each do |file|
          name = File.basename(file, File.extname(file))
          extension = File.extname(file).delete('.')

          deployer.logger.info("Applying: #{name}.#{extension}")

          case extension
          when 'sql'
            resource = File.read(file)
            name, _ = Utils::FilePath.extract_name_and_task(file)
            deploy_resource(task, name, resource, :sql)
          when 'yaml'
            yaml = YAML.safe_load(File.read(file), permitted_classes: [Symbol], symbolize_names: true)
            deploy_resource(task, name, yaml, :yaml)
          end
        end
      end

      def deploy_resource(task, name, data, format)
        resource = resource_repo.create(
          task: task,
          type: format,
          name: name,
          data: data,
          logger: deployer.logger,
          log_level: deployer.options[:log_level]
        )

        deployer.deploy_resource(resource)
      end

      def register_resource_classes
        # Routine Load
        resource_repo.register(:routine_load, :sql, Deployables::RoutineLoadSqlDeployable)
        resource_repo.register(:routine_load, :yaml, Deployables::RoutineLoadConfigDeployable)
        # Materialized View
        resource_repo.register(:materialized_view, :sql, Deployables::CreateMaterializedViewSqlDeployable)
      end

      def resource_dir(resource_type)
        options[:"#{resource_type}_dir"] || File.join(deployer.resource_dir, "#{resource_type}s")
      end

      def resource_task(resource_type) = resource_type.to_sym

      def resource_types = %i[routine_load materialized_view]
    end
  end
end
