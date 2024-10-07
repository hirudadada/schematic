# frozen_string_literal: true

module Schematic
  module Starrocks
    class Deployment
      attr_reader :deployer, :options

      RESOURCE_TYPES = %i[routine_load materialized_view]
      TASKS = %i[create]

      def initialize(deployer, opts = {})
        @options = opts
        yield @options if block_given?
        @deployer = deployer
      end

      def deploy_all
        deploy_routine_load
        deploy_materialized_view
      end

      def deploy_routine_load
        deploy_resources(routine_load_dir, :create_routine_load)
      rescue DeploymentError => e
        puts e.message
      end

      def deploy_materialized_view
        deploy_resources(materialized_view_dir, :create_materialized_view)
      rescue DeploymentError => e
        puts e.message
      end

      def materialized_view_dir
        @materialized_view_dir ||= init_materialized_view_dir
      end

      def routine_load_dir
        @routine_load_dir ||= init_routine_load_dir
      end

      protected

      def load(file)
        Class.new.instance_eval(File.read(file), file)
      end

      def validate_config_deployable(data)
        unless %i[name task].each { |key| data.include?(key)}
          raise ArgumentError, "'name' and 'task' must be specified."
        end

        unless data.keys.any? { |key| %i[config sql].include?(key) }
          raise ArgumentError, "Either 'config' or 'sql' must be present."
        end
      end

      def deploy_resources(dir, task)
        Dir.glob(File.join(dir, '*')).sort.each do |file|
          name = File.basename(file, File.extname(file))
          extension = File.extname(file).delete('.')

          case extension
          when 'sql'
            resource = File.read(file)
            name, _ = Utils::FilePath.extract_name_and_task(file)
            deploy_resource(task, name, resource, :sql)
          when 'json'
            json = JSON.parse(File.read(file))
            deploy_resource(task, name, json, :json)
          when 'rb'
            data = load(file)
            deploy_resource(task, name, data, :rb)
          end
        end
      end

      def deploy_resource(task, name, data, format)
        resource = case format
                   when :json
                     data = data.transform_keys(&:to_sym)  # json key is string type
                     validate_config_deployable(data)
                     create_config_deployable(task, name, data)
                   when :sql
                     data = { sql: data }
                     create_sql_deployable(task, name, data)
                   when :rb
                     validate_config_deployable(data)
                     create_rb_deployable(task, name, data)
                   end

        deployer.deploy_resource(resource)
      # rescue DeploymentError => e
      #   puts e.message
      # rescue => e
      #   puts "Error processing #{name}: #{e.message}"
      end

      def create_config_deployable(task, name, data)
        if data[:task] != task.to_s
          raise ArgumentError, "Unsupported task #{task} does not match data provided. #{data.inspect}"
        end

        if task == :create_routine_load
          Deployables::CreateRoutineLoadConfigDeployable.new(name:, data:)
        # elsif task == :materialized_view
        #   Deployables::CreateMaterializedViewConfigDeployable.new(name:, config:data)
        else
          raise ArgumentError, "Unsupported config task #{task}: #{data.inspect}"
        end
      end

      def create_sql_deployable(task, name, data)
        case task
        when :create_routine_load
          Deployables::CreateRoutineLoadSqlDeployable.new(name:, data:)
        when :create_materialized_view
          Deployables::CreateMaterializedViewSqlDeployable.new(name:, data:)
        else
          raise ArgumentError, "Unkown SQL task #{task}: #{data.inspect}"
        end
      end

      def create_rb_deployable(task, name, data)
        case task
        when :create_routine_load
          Deployables::CreateRoutineLoadSqlDeployable.new(name:, data:)
        when :create_materialized_view
          Deployables::CreateMaterializedViewSqlDeployable.new(name:, data:)
        else
          raise ArgumentError, "Unsupported type: #{data.inspect}"
        end
      end

      def init_routine_load_dir
        options[:routine_load_dir] || File.join(deployer.resource_dir, 'routine_loads')
      end

      def init_materialized_view_dir
        options[:materialized_view_dir] || File.join(deployer.resource_dir,
                                                    'materialized_views')
      end
    end
  end
end
