# frozen_string_literal: true

require 'json'

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

        template = File.read(File.join(template_dir, "#{template_name}.erb"))
        ERB.new(template).result_with_hash(context)
      end

      # def create_template(name, resource_type, data, format = :sql)
      def create_template(name, resource_type, format = :sql)
        dir = resource_type == :create_materialized_view ? materialized_view_dir : routine_load_dir
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        filename = "#{timestamp}_#{resource_type}_#{name}.#{format}"

        filepath = File.join(dir, filename)

        content = case format
                  when :sql
                    # data.inspect
                    sql_template(resource_type)
                  when :json
                    # data.to_json
                    JSON.pretty_generate(config_template(resource_type))
                  when :rb
                    rb_template
                  else
                    raise ArgumentError, "Unsupported type #{format} for #{__method__}"
                  end

        FileUtils.mkdir_p(dir)

        File.open(filepath, 'w') do |file|
          file.write(content)
        end
        puts "New deployment resource is created: #{filepath}"
      end

      def work_dir
        @work_dir ||= init_work_dir
      end

      def template_dir
        @template_dir ||= init_template_dir
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

      def sql_template(resource_type)
        # <<~SQL
        #   USE DATABASE `database_name`;
        #
        #   SHOW TABLES;
        # SQL
        case resource_type
        when :create_materialized_view
          Templates::CreateMaterializedViewSqlTemplate.new.create
        when :create_routine_load
          Templates::CreateRoutineLoadSqlTemplate.new.create
        else
          raise ArgumentError, "resource_type #{resource_type} is not supported."
        end
      end

      def config_template(resource_type)
        case resource_type
        when :create_routine_load
          Templates::CreateRoutineLoadConfigTemplate.new.create
          # Templates::CreateRoutineLoadConfigTemplate
        else
          raise ArgumentError, "resource_type #{resource_type} is not supported."
        end
      end

      def rb_template
        # TODO: specify with cases
        <<~RUBY
          # frozen_string_literal: true

          # # example.rb
          name = "custom_name"  # optional
          resource = "SELECT * FROM table"
        RUBY
      end

      def init_work_dir
        (options[:work_dir] || default_options[:work_dir])
      end

      def init_routine_load_dir
        options[:routine_load_dir] || File.join(template_dir, 'routine_loads')
      end

      def init_materialized_view_dir
        options[:materialized_view_dir] || File.join(template_dir,
                                                    'materialized_view')
      end

      def init_template_dir
        dir = Pathname.new(options[:resource_dir] || default_template_dir)
        dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
      end

      def default_template_dir
        File.join('templates', 'starrocks')
      end
    end
  end
end
