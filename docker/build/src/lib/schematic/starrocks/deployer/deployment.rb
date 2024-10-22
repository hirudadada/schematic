# frozen_string_literal: true

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

          puts "Applying: #{name}.#{extension}"

          case extension
          when 'sql'
            resource = File.read(file)
            name, _ = Utils::FilePath.extract_name_and_task(file)
            deploy_resource(task, name, resource, :sql)
          when 'json'
            json = JSON.parse(File.read(file), symbolize_names: true)
            deploy_resource(task, name, json, :json)
          when 'rb'
            data = load(file)
            task = data[:task] || task
            name = data[:name] || name
            deploy_resource(task, name, data, :rb)
          end
        end
      end

      def deploy_resource(task, name, data, format)
        resource = resource_repo.create(
          task: task,
          type: format,
          name: name,
          # data: format == :json ? data.transform_keys(&:to_sym) : data
          data: data
        )

        deployer.deploy_resource(resource)
      # rescue DeploymentError => e
      #   puts e.message
      # rescue => e
      #   puts "Error processing #{name}: #{e.message}"
      end

      def register_resource_classes
        resource_repo.register(:create_routine_load, :sql, Deployables::CreateRoutineLoadSqlDeployable)
        resource_repo.register(:create_routine_load, :json, Deployables::CreateRoutineLoadConfigDeployable)
        resource_repo.register(:create_routine_load, :rb, Deployables::CreateRoutineLoadRbDeployable)
        resource_repo.register(:create_materialized_view, :sql, Deployables::CreateMaterializedViewSqlDeployable)
        resource_repo.register(:create_materialized_view, :rb, Deployables::CreateMaterializedViewRbDeployable)
      end

      def resource_dir(resource_type)
        options[:"#{resource_type}_dir"] || File.join(deployer.resource_dir, "#{resource_type}s")
      end

      def resource_task(resource_type) = "create_#{resource_type}".to_sym

      def resource_types = %i[routine_load, materialized_view]

      def load(file)
        Class.new.instance_eval(File.read(file), file)
      end
    end
  end
end
