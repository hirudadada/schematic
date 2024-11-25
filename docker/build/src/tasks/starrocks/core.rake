# frozen_string_literal: true

require_relative '../../lib/schematic/starrocks'

namespace :starrocks do
  namespace :routine_load do
    desc 'Deploy StarRocks resources'
    task :deploy do
      # StarRocks connection details come from database.env
      deployer = Schematic::Starrocks::Deployer::Core.new(
        log_level: ENV['LOG_LEVEL']&.to_i || Logger::INFO,
        sql_log_level: ENV['SQL_LOG_LEVEL']&.to_sym || :debug,
        resource_dir: ENV['RESOURCE_DIR'] || 'db/starrocks',
        work_dir: ENV['WORK_DIR']&.strip&.empty? ? nil : ENV['WORK_DIR']&.strip
      )

      resource_repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new

      deployment = Schematic::Starrocks::Deployer::Deployment.new(deployer, resource_repo) do |options|
        options[:hydrate] = ENV['HYDRATE'] != 'false'
        options[:migration_mode] = ENV['MIGRATION_MODE'] != 'false'
        options[:generate_configmap] = ENV['GENERATE_CONFIGMAP'] == 'true'
      end

      deployment.deploy_all
    end
  end
end

