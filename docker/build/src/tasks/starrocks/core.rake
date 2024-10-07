# frozen_string_literal: true

require_relative '../../lib/schematic/starrocks'

namespace :starrocks do # rubocop:disable Metrics/BlockLength
  %i[routine_load materialized_view].each do |resource_type|
    resource_type_name = resource_type.to_s.split('_').map(&:capitalize).join(' ')
    resource_type_plural = "#{resource_type_name}s"

    namespace resource_type do
      desc "Create a #{resource_type_name} template (Available formats: sql, json, rb)"
      task :create, [:name, :format] do |_, args|
        unless args[:name] && args[:format]
          abort "Aborted! #{resource_type_name} name and format are required. Usage: rake starrocks:#{resource_type}:create[name,format_type]" # rubocop:disable Layout/LineLength
        end

        unless %w[sql json rb].include?(args[:format])
          abort "Aborted! Invalid format '#{args[:format]}'. Available formats: sql, json, rb"
        end

        deployer = Schematic::Starrocks::Deployer.new
        manager = Schematic::Starrocks::TemplateManager.new(resource_dir: deployer.resource_dir)
        manager.create_template("create_#{resource_type}".to_sym, args[:name], args[:format].to_sym)
      end

      desc "Apply #{resource_type_plural}"
      task :deploy do |_, _args|
        puts "\nApplying #{resource_type_plural} to StarRocks...\n"

        deployer = Schematic::Starrocks::Deployer.new
        repo = Schematic::Starrocks::Deployables::DeployableResourceRepository.new
        Schematic::Starrocks::Deployment.new(deployer, repo).deploy_all([resource_type])
      end
    end
  end
end
