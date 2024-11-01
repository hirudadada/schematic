# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableDeployableResource < DeployableResource
        def deploy(client)
          hydrated_data = hydrate_placeholders(data)
          deploy_hydrated(client, hydrated_data)
        end

        protected

        def deploy_hydrated(client, hydrated_data)
          raise NotImplementedError, "#{self.class} must implement 'deploy_hydrated' method"
        end

        def hydrate_placeholders(data)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create

          replacements = {
            'KAFKA_BROKER_LIST' => provider.kafka_config[:broker_list],
            'KAFKA_SECURITY_PROTOCOL' => provider.kafka_config[:security][:protocol],
            'KAFKA_SASL_MECHANISM' => provider.kafka_config[:security][:mechanism],
            'KAFKA_SASL_USERNAME' => provider.kafka_config[:security][:username],
            'KAFKA_SASL_PASSWORD' => provider.kafka_config[:security][:password],
            'KAFKA_SSL_VERIFY' => provider.kafka_config[:security][:ssl_verify],
            'KAFKA_PARTITIONS' => provider.kafka_config[:partitions],
            'KAFKA_OFFSET' => provider.kafka_config[:offset],
            'SCHEMA_REGISTRY_URL' => provider.schema_registry_config[:url],
            'SCHEMA_REGISTRY_USERNAME' => provider.schema_registry_config[:auth][:username],
            'SCHEMA_REGISTRY_PASSWORD' => provider.schema_registry_config[:auth][:password]
          }

          if data.is_a?(String)
            data.gsub(/\{\{(\w+)\}\}/) { |_| replacements[$1] }
          else
            deep_transform_values(data) do |value|
              value.is_a?(String) ? value.gsub(/\{\{(\w+)\}\}/) { |_| replacements[$1] } : value
            end
          end
        end

        def deep_transform_values(obj, &block)
          case obj
          when Hash
            obj.transform_values { |value| deep_transform_values(value, &block) }
          when Array
            obj.map { |value| deep_transform_values(value, &block) }
          else
            yield(obj)
          end
        end
      end
    end
  end
end 
