# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadConfigDeployable < HydratableDeployableResource
        include RoutineLoadConfigDeployable::DeploymentMethods
        include Defaults

        def deploy_hydrated(client, hydrated_data)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create

          # Add operation-specific data
          hydrated_data = case hydrated_data[:operation].to_sym
                         when :create
                           kafka_config = provider.kafka_config.merge(
                             topic: hydrated_data[:table]
                           )
                           hydrated_data.merge(
                             db: provider.db_name,
                             columns: hydrated_data[:columns] || DEFAULT_COLUMNS,
                             properties: provider.properties(:create),
                             kafka: kafka_config,
                             schema_registry: provider.schema_registry_config
                           )
                         when :alter
                           properties = provider.properties(:alter)
                           hydrated_data.merge(
                             db: provider.db_name,
                             properties: Types::AlterableProperties[properties]
                           )
                         else
                           hydrated_data.merge(
                             db: provider.db_name
                           )
                         end

          # Extract load info
          load_info = extract_load_info(hydrated_data)

          client.transaction do
            client.run("USE #{provider.db_name};")

            if hydrated_data[:operation].to_sym == :create && !@strategy
              check_and_stop_existing(client, provider.db_name, hydrated_data[:routine_name])
            end

            if @strategy
              @strategy.execute(client, [build_sql(hydrated_data)], load_info)
            else
              execute_operation(client, hydrated_data)
            end
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
