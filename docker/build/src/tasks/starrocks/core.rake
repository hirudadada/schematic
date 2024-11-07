# frozen_string_literal: true

require_relative '../../lib/schematic/starrocks'

namespace :starrocks do
  namespace :routine_load do
    desc "Deploy routine loads"
    task :deploy, [:migration_mode] do |_, args|
      puts "\nApplying Routine Loads to StarRocks...\n"

      migration_mode = args[:migration_mode].nil? ? true : args[:migration_mode].to_s.downcase == 'true'
      
      # deployer = Schematic::Starrocks::Deployer::Core.new(log_level: Logger::DEBUG)
      deployer = Schematic::Starrocks::Deployer::Core.new
      repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new
      
      deployment = Schematic::Starrocks::Deployer::Deployment.new(
        deployer, 
        repo, 
        migration_mode: migration_mode
      )
      
      deployment.deploy_all([:routine_load])
    end
  end
end
# require 'schematic/starrocks'
# 
# namespace :starrocks do
#   desc 'Deploy StarRocks resources'
#   task :deploy do
#     deployer = Schematic::Starrocks::Deployer::Core.new
# 
#     resource_repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new
# 
#     deployment = Schematic::Starrocks::Deployer::Deployment.new(deployer, resource_repo) do |options|
#       options[:hydrate] = ENV['STARROCKS_HYDRATE'] != 'false'
#       options[:migration_mode] = ENV['STARROCKS_MIGRATION_MODE'] != 'false'
#       options[:generate_configmap] = ENV['STARROCKS_GENERATE_CONFIGMAP'] == 'true'
#     end
# 
#     deployment.deploy_all
#   end
# end 
# 

