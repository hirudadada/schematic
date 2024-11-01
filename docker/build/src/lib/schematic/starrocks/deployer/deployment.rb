# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    # # Default behavior - hydration enabled
    # deployment = Deployment.new(deployer, repo)
    # # Disable hydration
    # deployment = Deployment.new(deployer, repo, hydrate: false)
    # # Force configmap generation in development
    # deployment = Deployment.new(deployer, repo, generate_configmap: true)
    # # Both options
    # deployment = Deployment.new(deployer, repo, hydrate: false, generate_configmap: true)
    class Deployment
      attr_reader :deployer, :resource_repo, :options, :provider

      def initialize(deployer, resource_repo, opts = {})
        @options = opts
        yield @options if block_given?
        @deployer = deployer
        @resource_repo = resource_repo
        @provider = Providers::RoutineLoadConfigProvider.create

        # Generate configmap if needed
        generate_configmap if generate_configmap?

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
          log_level: deployer.options[:log_level],
          provider: provider
        )

        deployer.deploy_resource(resource)
      end

      def register_resource_classes
        if hydrate_enabled?
          # Use hydratable versions by default
          resource_repo.register(:routine_load, :sql, Deployables::HydratableRoutineLoadSqlDeployable)
          resource_repo.register(:routine_load, :yaml, Deployables::HydratableRoutineLoadConfigDeployable)
        else
          # Use non-hydratable versions if explicitly disabled
          resource_repo.register(:routine_load, :sql, Deployables::RoutineLoadSqlDeployable)
          resource_repo.register(:routine_load, :yaml, Deployables::RoutineLoadConfigDeployable)
        end
        resource_repo.register(:materialized_view, :sql, Deployables::CreateMaterializedViewSqlDeployable)
      end

      def resource_dir(resource_type)
        options[:"#{resource_type}_dir"] || File.join(deployer.resource_dir, "#{resource_type}s")
      end

      def resource_task(resource_type) = resource_type.to_sym

      def resource_types = %i[routine_load materialized_view]

      private

      def hydrate_enabled?
        # Default to true unless explicitly set to false
        options[:hydrate] != false
      end

      def generate_configmap?
        # Generate configmap in when explicitly requested
        options[:generate_configmap]
      end

      def generate_configmap
        generator = Generator::RoutineLoadConfigMap.new(
          work_dir: deployer.work_dir,
          gitops_dir: File.join(deployer.work_dir, 'gitops')
        )
        generator.generate
      end
    end
  end
end
