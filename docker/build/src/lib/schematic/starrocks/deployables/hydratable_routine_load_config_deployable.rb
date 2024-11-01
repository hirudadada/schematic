# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadConfigDeployable < HydratableDeployableResource
        include RoutineLoadConfigDeployable::DeploymentMethods

        def deploy_hydrated(client, hydrated_data)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create

          client.transaction do
            client.run("USE #{provider.db_name};")

            if hydrated_data[:operation].to_sym == :create
              check_and_stop_existing(client, provider.db_name, hydrated_data[:routine_name])
            end

            execute_operation(client, hydrated_data)
          end
          logger.info("Deployed routine load operation: #{hydrated_data[:operation]} for #{hydrated_data[:routine_name]}")
        end
      end
    end
  end
end 
