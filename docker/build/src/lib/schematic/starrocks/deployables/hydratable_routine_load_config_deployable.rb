# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadConfigDeployable < HydratableDeployableResource
        include RoutineLoadConfigDeployable::DeploymentMethods
        include Defaults

        def deploy_hydrated(client, hydrated_data)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create
          load_info = extract_load_info(hydrated_data)

          client.transaction do
            client.run("USE #{provider.db_name};")
            
            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, [build_sql(hydrated_data)], load_info)
          end
          logger.info("Deployed routine load operation: #{hydrated_data[:operation]} for #{hydrated_data[:routine_name]}")
        end

        private

        def build_sql(data)
          case data[:operation].to_sym
          when :create
            create_routine_load_sql(data)
          when :alter
            alter_routine_load_sql(data)
          else
            Types::StrictString["#{data[:operation].to_s.upcase} ROUTINE LOAD FOR `#{data[:routine_name]}`;"]
          end
        end
      end
    end
  end
end 
