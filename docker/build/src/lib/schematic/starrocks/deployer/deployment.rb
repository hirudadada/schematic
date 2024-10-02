# frozen_string_literal: true

module Schematic
  module Starrocks
    class Deployment
      attr_reader :deployer, :options

      def initialize(deployer, opts = {})
        @options = default_options.merge(opts)
        @deployer = deployer
      end

      def deploy_all
        deploy_resources(materialize_view_dir, :raw_sql)
        deploy_resources(routine_load_dir, :config)
      rescue DeploymentError => e
        puts e.message
      end

      def template_dir
        @resource_dir ||= init_template_dir
      end

      def materialize_view_dir
        @materialize_view_dir ||= init_materialize_view_dir
      end

      def routine_load_dir
        @routine_load_dir ||= init_routine_load_dir
      end

      protected

      def init_routine_load_dir
        options[:routine_load_dir] || File.join(deployer.deployment_dir, 'routine_loads')
      end

      def init_template_dir
        dir = Pathname.new(options[:resource_dir] || default_template_dir)
        dir.absolute? ? dir.to_s : File.join(deployer.work_dir, dir.to_s)
      end

      def default_template_dir
        File.join('templates', 'starrocks')
      end

      def init_materialize_view_dir
        options[:materialize_view_dir] || File.join(deployer.deployment_dir,
          'materialized_view')
      end

      def deploy_resources(dir, type)
        Dir.glob(File.join(dir, '*')).each do |file|
          name = File.basename(file, File.extname(file))
          extension = File.extname(file).delete('.')

          case extension
          when 'sql'
            resource = eval(File.read(file))
            deploy_resource(name, resource, type)
          when 'json'
            json = JSON.parse(File.read(file))
            deploy_resource(name, json, type)
          end
        end
      end

      def deploy_resource(name, data, type)
        resource = case type
        when :raw_sql
          RawSqlResource.new(name, data)
        when :config
          ConfigResource.new(name, data)
        end

        deployer.deploy_resource(resource)
      rescue DeploymentError => e
        puts e.message
      end
    end
  end
end
