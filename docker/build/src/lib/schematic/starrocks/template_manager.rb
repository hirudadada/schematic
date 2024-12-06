# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'templates'
require_relative 'providers/routine_load_config_provider'

module Schematic
  module Starrocks
    class TemplateManager
      attr_reader :resource_dir, :options

      def initialize(resource_dir:, **opts)
        @resource_dir = resource_dir
        @options = { 
          migration_mode: true,
          dynamic_sql: false 
        }.merge(opts)
      end

      def create_template(resource_type, table_name, format, operation = :create)
        dir = case resource_type
             when :routine_load
               if options[:migration_mode]
                 File.join(@resource_dir, 'routine_loads', 'migrations')
               else
                 File.join(@resource_dir, 'routine_loads')
               end
             else
               File.join(@resource_dir, resource_type.to_s)
             end

        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        
        template = template_for(resource_type, table_name, format, operation)
        content = template.create

        case format
        when :yaml
          write_template(dir, template.name, format, YAML.dump(content))
        else
          write_template(dir, template.name, format, content)
        end
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

      def template_for(resource_type, table_name, format, operation)
        case [resource_type, format]
        when [:routine_load, :sql]
          if options[:dynamic_sql]
            Templates::DynamicRoutineLoadSqlTemplate.new(table_name, operation, nil, logger)
          else
            Templates::RoutineLoadSqlTemplate.new(table_name, operation, nil, logger)
          end
        when [:routine_load, :yaml]
          Templates::RoutineLoadConfigTemplate.new(table_name, operation, nil, logger)
        else
          raise ArgumentError, "Unsupported resource type: #{resource_type} or format: #{format}"
        end
      end

      def write_template(dir, name, format, content)
        extension = format == :yaml ? 'yaml' : 'sql'
        filename = "#{name}.#{extension}"
        filepath = File.join(dir, filename)

        File.write(filepath, content)
        puts "New deployment resource is created: #{filepath}"
      end
    end
  end
end
