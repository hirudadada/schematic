# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableDeployableResource < DeployableResource
        def deploy(client)
          hydrated_data = hydrate_placeholders(data)
          deploy_hydrated(client, hydrated_data)
        end

        def deploy_hydrated(client, hydrated_data)
          raise NotImplementedError, "#{self.class} must implement 'deploy_hydrated' method"
        end

        protected

        def hydrate_placeholders(data)
          placeholders = {
            'DB_NAME' => options[:provider]&.db_name || 'schematic',
            'KAFKA_BROKER_LIST' => options[:provider]&.kafka_config[:broker_list],
            'KAFKA_PARTITIONS' => options[:provider]&.kafka_config[:partitions],
            'KAFKA_OFFSET' => options[:provider]&.kafka_config[:offset],
            'KAFKA_SECURITY_PROTOCOL' => options[:provider]&.kafka_config[:security][:protocol],
            'KAFKA_SASL_MECHANISM' => options[:provider]&.kafka_config[:security][:mechanism],
            'KAFKA_SASL_USERNAME' => options[:provider]&.kafka_config[:security][:username],
            'KAFKA_SASL_PASSWORD' => options[:provider]&.kafka_config[:security][:password],
            'KAFKA_SSL_VERIFY' => options[:provider]&.kafka_config[:ssl_verfy].to_s,
            'SCHEMA_REGISTRY_URL' => options[:provider]&.schema_registry_config[:url],
            'SCHEMA_REGISTRY_USERNAME' => options[:provider]&.schema_registry_config[:auth][:username],
            'SCHEMA_REGISTRY_PASSWORD' => options[:provider]&.schema_registry_config[:auth][:password]
          }

          case data
          when String
            data.gsub(/\{\{(\w+)\}\}/) { |_| placeholders[$1] }
          when Hash
            data.transform_values { |v| hydrate_placeholders(v) }
          when Array
            data.map { |v| hydrate_placeholders(v) }
          else
            data
          end
        end
      end
    end
  end
end 
