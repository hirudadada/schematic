# frozen_string_literal: true

require 'fileutils'

require_relative '../../lib/schematic/starrocks'

namespace :starrocks do # rubocop:disable Metrics/BlockLength
  namespace :materialized_view do
    desc 'Create a materialized view template (Available formats: sql, json, rb)'
    task :create, [:name, :format] do |_, args|
      unless args[:name] && args[:format]
        abort 'Aborted! Materialized View name and format are required. Usage: rake starrocks:materialized_view:create[view_name,format_type]' # rubocop:disable Layout/LineLength
      end

      unless %w[sql json rb].include?(args[:format])
        abort "Aborted! Invalid format '#{args[:format]}'. Available formats: sql, json, rb"
      end

      deployer = Schematic::Starrocks::Deployer.new
      manager = Schematic::Starrocks::TemplateManager.new(resource_dir: deployer.resource_dir)
      manager.create_template(:create_materialized_view, args[:name], args[:format].to_sym)
    end

    desc 'Apply materialized views'
    task :deploy do |_, _args|
      puts "\nApplying materialized views to StarRocks...\n"

      deployer = Schematic::Starrocks::Deployer.new
      Schematic::Starrocks::Deployment.new(deployer).deploy_routine_load
    end
  end

  namespace :routine_load do
    desc 'Create a routine load template (Available formats: sql, json, rb)'
    task :create, [:name, :format] do |_, args|
      unless args[:name] && args[:format]
        abort 'Aborted! Routine load name and format are required. Usage: rake starrocks:routine_load:create[load_name,format_type]' # rubocop:disable Layout/LineLength
      end

      unless %w[sql json rb].include?(args[:format])
        abort "Aborted! Invalid format '#{args[:format]}'. Available formats: sql, json, rb"
      end

      deployer = Schematic::Starrocks::Deployer.new
      manager = Schematic::Starrocks::TemplateManager.new(resource_dir: deployer.resource_dir)
      manager.create_template(:create_routine_load, args[:name], args[:format].to_sym)
    end

    desc 'Apply routine loads'
    task :deploy do |_, _args|
      puts "\nApplying routine loads to StarRocks...\n"

      deployer = Schematic::Starrocks::Deployer.new
      Schematic::Starrocks::Deployment.new(deployer).deploy_routine_load
    end
  end
end
