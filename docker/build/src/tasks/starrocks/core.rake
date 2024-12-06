# frozen_string_literal: true

require_relative '../../lib/schematic/starrocks'

require_relative '../../lib/schematic/starrocks/generator'
require_relative '../../lib/schematic/starrocks/deployables/states/routine_load_state'

namespace :starrocks do
  namespace :routine_load do
    desc "Generate a new routine load migration"
    task :generate, [:table_name, :operation, :format, :migration_mode] do |_, args|
      unless args[:table_name] && args[:operation]
        abort "Usage: rake starrocks:routine_load:generate[table_name,operation,format,migration_mode]"
      end

      operation = args[:operation]
      unless %w[create alter pause resume stop].include?(operation)
        abort "Invalid operation. Must be one of: create, alter, pause, resume, stop"
      end

      format = args[:format] || 'yaml'
      unless %w[sql yaml].include?(format)
        abort "Invalid format. Must be one of: sql, yaml"
      end

      # Default to true unless explicitly set to 'false'
      migration_mode = args[:migration_mode].nil? ? true : args[:migration_mode].to_s.downcase == 'true'

      # Control dynamic SQL generation
      dynamic_sql = ENV.fetch('DYNAMIC_SQL', 'false') == 'true'
      puts "SQL Mode: #{dynamic_sql ? 'Dynamic' : 'Static'}" if format == 'sql'

      manager = Schematic::Starrocks::TemplateManager.new(
        resource_dir: ENV['STARROCKS_RESOURCE_DIR'] || 'db/starrocks',
        migration_mode: migration_mode,
        dynamic_sql: dynamic_sql  # Pass the flag to template manager
      )

      manager.create_template(:routine_load, args[:table_name], format.to_sym, operation.to_sym)

      puts "Generated migration: #{operation}_#{args[:table_name]}_routine_load.#{format}"
      puts "Migration mode: #{migration_mode ? 'enabled' : 'disabled'}"
    end

    desc "Show routine load status"
    task :status do
      core = Schematic::Starrocks::Deployer::Core.new

      puts "\nChecking Routine Loads status in StarRocks...\n"

      # Ensure migrations table exists
      begin
        Schematic::Starrocks::Deployables::States::MigrationTracker.ensure_migrations_table(core.client)
      rescue => e
        puts "Failed to create migrations table: #{e.message}"
      end

      # Show migrations table status
      begin
        migrations = Schematic::Starrocks::Deployables::States::MigrationTracker.get_migrations(core.client)
        if migrations.any?
          puts "\nApplied Migrations:"
          migrations.each do |m|
            puts "  #{m[:version]} - #{m[:operation]} #{m[:table_name]} (#{m[:applied_at]})"
          end
        end
      rescue => e
        puts "Error fetching migrations: #{e.message}"
      end
    end

    desc 'Deploy StarRocks resources'
    task :deploy do
      # Control dynamic SQL deployment
      dynamic_sql = ENV.fetch('DYNAMIC_SQL', 'false') == 'true'

      deployer = Schematic::Starrocks::Deployer::Core.new(
        log_level: ENV['LOG_LEVEL']&.to_i || Logger::INFO,
        sql_log_level: ENV['SQL_LOG_LEVEL']&.to_sym || :debug,
        resource_dir: ENV['RESOURCE_DIR'] || 'db/starrocks',
        work_dir: ENV['WORK_DIR']&.strip&.empty? ? nil : ENV['WORK_DIR']&.strip,
        dynamic_sql: dynamic_sql  # Pass the flag to core
      )

      resource_repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new()

      deployment = Schematic::Starrocks::Deployer::Deployment.new(deployer, resource_repo) do |options|
        options[:hydrate] = ENV['HYDRATE'] != 'false'
        options[:migration_mode] = ENV['MIGRATION_MODE'] != 'false'
        options[:generate_configmap] = ENV['GENERATE_CONFIGMAP'] == 'true'
        options[:dynamic_sql] = dynamic_sql
      end

      deployment.deploy_all
    end
  end

  namespace :gitops do
    desc "Generate GitOps config for StarRocks"
    task :generate do
      generator = Schematic::Starrocks::Generator::RoutineLoadGitOpsConfig.new
      generator.generate
      puts "Generated GitOps config for StarRocks"
    end
  end
end
