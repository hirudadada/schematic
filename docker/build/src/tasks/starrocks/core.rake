# frozen_string_literal: true

require 'logger'
require_relative '../../lib/schematic/starrocks'

namespace :starrocks do # rubocop:disable Metrics/BlockLength
  %i[routine_load].each do |resource_type|
    resource_type_name = resource_type.to_s.split('_').map(&:capitalize).join(' ')
    resource_type_plural = "#{resource_type_name}s"

    namespace resource_type do
      desc "Create a #{resource_type_name} template (Available formats: sql, yaml)"
      task :create, [:operation, :table_name, :format] do |_, args|
        unless args[:table_name] && args[:format]
          abort "Aborted! Table name and format are required. Usage: rake starrocks:#{resource_type}:create[operation,table_name,format_type]" # rubocop:disable Layout/LineLength
        end

        unless %w[sql yaml].include?(args[:format])
          abort "Aborted! Invalid format '#{args[:format]}'. Available formats: sql, yaml"
        end

        operation = args[:operation] || 'create'
        unless %w[create pause resume stop alter].include?(operation)
          abort "Aborted! Invalid operation '#{operation}'. Available operations: create, pause, resume, stop, alter"
        end

        deployer = Schematic::Starrocks::Deployer.new(log_level: Logger::INFO)
        manager = Schematic::Starrocks::TemplateManager.new(resource_dir: deployer.resource_dir)
        manager.create_template(resource_type, args[:table_name], args[:format].to_sym, operation.to_sym)
      end

      desc "Apply #{resource_type_plural}"
      task :deploy do |_, _args|
        puts "\nApplying #{resource_type_plural} to StarRocks...\n"

        deployer = Schematic::Starrocks::Deployer.new(log_level: Logger::INFO, log_sql: false, sql_log_level: :debug)
        repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new
        Schematic::Starrocks::Deployment.new(deployer, repo, generate_configmap: false).deploy_all([resource_type])
      end
      #
      # desc "Convert between SQL and YAML formats"
      # task :convert, [:source, :target_format] do |_, args|
      #   unless args[:source] && args[:target_format]
      #     abort "Usage: rake starrocks:routine_load:convert[source_file,target_format]"
      #   end
      #
      #   unless %w[sql yaml].include?(args[:target_format])
      #     abort "Invalid target format. Must be 'sql' or 'yaml'"
      #   end
      #
      #   source = File.read(args[:source])
      #   converter = Schematic::Starrocks::Converters::RoutineLoadConverter.new
      #
      #   result = if args[:source].end_with?('.sql')
      #              converter.sql_to_yaml(source)
      #            else
      #              converter.yaml_to_sql(source)
      #            end
      #
      #   target_file = args[:source].sub(/\.(sql|ya?ml)$/, ".#{args[:target_format]}")
      #   File.write(target_file, result)
      #   puts "Converted #{args[:source]} to #{target_file}"
      # end
    end
  end
end
