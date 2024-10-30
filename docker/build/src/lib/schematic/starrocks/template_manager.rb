# frozen_string_literal: true

require 'yaml'
require_relative 'templates'

module Schematic
  module Starrocks
    class TemplateManager
      attr_reader :options

      def initialize(opts = {})
        @options = default_options.merge!(opts)
        yield options if block_given?
      end

      def render(template_name, context = {})
        template_name = template.to_s if template_name.is_a? Symbol

        template = File.read(File.join(resource_dir, "#{template_name}.erb"))
        ERB.new(template).result_with_hash(context)
      end

      def create_template(task, name, format = :sql, operation = :create)
        dir = task == :materialized_view ? materialized_view_dir : routine_load_dir
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        
        template_name = if task == :routine_load && operation != :create
                         "#{operation}_#{name}"
                       else
                         name
                       end
        
        filepath = Utils::FilePath.generate_filepath(dir, task, template_name, format, timestamp)

        begin
          content = case format
                    when :sql
                      sql_template(task, name, operation)
                    when :yaml
                      config_template(task, name, operation)
                    else
                      raise ArgumentError, "Unsupported type #{format} for #{__method__}"
                    end
          FileUtils.mkdir_p(dir)

          File.open(filepath, 'w') do |file|
            file.write(content)
          end
          puts "New deployment resource is created: #{filepath}"
        rescue ArgumentError => e
          puts "Failed to create #{format} resource. #{e.message}"
        end
      end

      def sql_template(task, name, operation = :create)
        case task
        when :materialized_view
          Templates::CreateMaterializedViewSqlTemplate.new(name).create
        when :routine_load
          Templates::RoutineLoadSqlTemplate.new(name, operation).create
        else
          raise ArgumentError, "task #{task} is not supported."
        end
      end

      def config_template(task, name, operation = :create)
        case task
        when :routine_load
          Templates::RoutineLoadConfigTemplate.new(name, operation).create
        else
          raise ArgumentError, "Unknown deployable type: #{task}"
        end
      end

      def work_dir
        @work_dir ||= init_work_dir
      end

      def resource_dir
        @resource_dir ||= init_resource_dir
      end

      def materialized_view_dir
        @materialized_view_dir ||= init_materialized_view_dir
      end

      def routine_load_dir
        @routine_load_dir ||= init_routine_load_dir
      end

      protected

      def default_options = {
        work_dir: Dir.pwd
      }

      def init_work_dir
        (options[:work_dir] || default_options[:work_dir])
      end

      def init_routine_load_dir
        options[:routine_load_dir] || File.join(resource_dir, 'routine_loads')
      end

      def init_materialized_view_dir
        options[:materialized_view_dir] || File.join(resource_dir,
                                                    'materialized_views')
      end

      def init_resource_dir
        dir = Pathname.new(options[:resource_dir] || default_resource_dir)
        dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
      end

      def default_resource_dir
        File.join('templates', 'starrocks')
      end
    end
  end
end
