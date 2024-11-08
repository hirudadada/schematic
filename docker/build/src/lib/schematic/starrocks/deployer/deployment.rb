# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    module Deployer
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
          @options = default_options.merge!(opts)
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
        rescue StandardError => e
          deployer.logger.error("Stopping deployment")
          exit(1)  # Stop deployment with error status
        end

        protected

        def deploy_resource_types(resource_types = nil)
          resource_types_to_deploy = resource_types || self.resource_types
          resource_types_to_deploy.each do |resource_type|
            deploy_resources(resource_dir(resource_type), resource_type)
          end
        end

        def deploy_resources(dir, task)
          deployer.logger.info("Looking for files in: #{dir}")
          files = Dir.glob(File.join(dir, '*'))
          deployer.logger.debug("Found files: #{files.inspect}")

          files.sort.each do |file|
            name = File.basename(file, File.extname(file))
            extension = File.extname(file).delete('.')

            deployer.logger.debug("Processing file: #{name} with extension: #{extension}")

            case extension
            when 'sql'
              resource = File.read(file)
              deployer.logger.debug("Deploying SQL resource: #{name}")
              deploy_resource(task, name, resource, :sql)
            when 'yaml', 'yml'
              deployer.logger.debug("Reading YAML file: #{file}")
              content = File.read(file)
              deployer.logger.debug("YAML content: #{content}")
              if content.nil? || content.strip.empty?
                deployer.logger.error("Empty YAML file: #{file}")
                next
              end
              yaml = YAML.load(content, permitted_classes: [Symbol])
              yaml = symbolize_keys(yaml) if yaml.is_a?(Hash)
              deployer.logger.debug("Parsed YAML: #{yaml.inspect}")
              deploy_resource(task, name, yaml, :yaml)
            end
          end
        end

        def deploy_resource(task, name, data, format)
          deployer.logger.debug("Creating resource: task=#{task}, name=#{name}, format=#{format}")
          begin
            deployer.logger.debug("Resource data: #{data.inspect}")
            resource = resource_repo.create(
              task: task,
              type: format,
              name: name,
              data: data,
              logger: deployer.logger,
              log_level: deployer.options[:log_level],
              provider: provider,
              migration_mode: options[:migration_mode]
            )
            deployer.logger.debug("Created resource: #{resource.class}")
            deployer.logger.debug("Resource strategy: #{resource.strategy&.class}")
            deployer.deploy_resource(resource)
          rescue StandardError => e
            deployer.logger.error("Error deploying resource: #{e.message}")
            raise  # Re-raise to stop deployment
          end
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
          case resource_type
          when :routine_load
            if options[:migration_mode]
              File.join(deployer.resource_dir, 'routine_loads', 'migrations')
            else
              File.join(deployer.resource_dir, 'routine_loads')
            end
          else
            File.join(deployer.resource_dir, resource_type.to_s.gsub('_', '/'))
          end
        end

        def resource_types
          [:routine_load]
        end

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

        def default_options
          {
            migration_mode: true  # Enable migration mode by default
          }
        end

        def symbolize_keys(hash)
          hash.transform_keys(&:to_sym).transform_values do |value|
            case value
            when Hash then symbolize_keys(value)
            when Array then value.map { |v| v.is_a?(Hash) ? symbolize_keys(v) : v }
            else value
            end
          end
        end
      end
    end
  end
end
