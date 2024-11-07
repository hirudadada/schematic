# frozen_string_literal: true

module Schematic
  module Starrocks
    module Providers
      class RoutineLoadConfigProvider
        include Defaults

        attr_reader :db_name, :kafka_config, :schema_registry_config

        def self.create
          new.prepare
        end

        def initialize
          @db = nil
          @kafka_broker_list = nil
          @kafka_partitions = nil
          @kafka_offset = nil
          @kafka_sasl_username = nil
          @kafka_sasl_password = nil
          @schema_registry_url = nil
          @sink_username = nil
          @sink_password = nil
          @properties = init_properties
        end

        def prepare
          @db = fetch_env('DB_NAME', 'schematic')
          @kafka_broker_list = fetch_env('KAFKA_BROKER_LIST', 'broker1:9092,broker2:9092')
          @kafka_partitions = fetch_env('KAFKA_PARTITIONS', '0,1,2')
          @kafka_offset = fetch_env('KAFKA_OFFSET', 'OFFSET_BEGINNING')
          @kafka_sasl_username = fetch_env('KAFKA_SASL_USERNAME', 'kafka_user')
          @kafka_sasl_password = decrypt_kafka_password
          @schema_registry_url = fetch_env('SCHEMA_REGISTRY_URL', 'schema-registry:8081')
          @sink_username = fetch_env('SCHEMA_REGISTRY_USERNAME', 'registry_user')
          @sink_password = decrypt_schema_registry_password

          validate!
          self
        end

        def properties(operation = :create)
          case operation.to_sym
          when :create
            @properties
          when :alter
            # Only return alterable properties without validation
            @properties.select { |k, _| ALTERABLE_PROPERTIES.include?(k) }
          else
            {}
          end
        end

        def db_name
          @db
        end

        def kafka_config
          {
            broker_list: @kafka_broker_list,
            partitions: @kafka_partitions,
            offset: @kafka_offset,
            security: {
              protocol: 'SASL_SSL',
              mechanism: 'PLAIN',
              username: @kafka_sasl_username,
              password: @kafka_sasl_password,
              ssl_verify: false
            }
          }
        end

        def schema_registry_config
          Types::SchemaRegistryConfig[{
            url: @schema_registry_url,
            auth: {
              username: @sink_username,
              password: @sink_password
            }
          }]
        end

        private

        def fetch_env(key, default = nil)
          ENV.fetch(key, default)&.strip
        end

        def decrypt_kafka_password
          encrypted = fetch_env('KAFKA_SASL_PASSWORD_ENCRYPTED')
          return fetch_env('KAFKA_SASL_PASSWORD') if encrypted.nil? || encrypted.empty?

          Schematic::Cipher.new.decrypt(encrypted).strip
        end

        def decrypt_schema_registry_password
          encrypted = fetch_env('SCHEMA_REGISTRY_PASSWORD_ENCRYPTED')
          return fetch_env('SCHEMA_REGISTRY_PASSWORD') if encrypted.nil? || encrypted.empty?

          Schematic::Cipher.new.decrypt(encrypted).strip
        end

        def validate!
          validate_kafka_credentials!
          validate_schema_registry_credentials!
        end

        def validate_kafka_credentials!
          if ENV['KAFKA_SASL_PASSWORD'].nil? && ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'].nil?
            raise ArgumentError, "Either KAFKA_SASL_PASSWORD or KAFKA_SASL_PASSWORD_ENCRYPTED must be provided"
          end
        end

        def validate_schema_registry_credentials!
          if ENV['SCHEMA_REGISTRY_PASSWORD'].nil? && ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'].nil?
            raise ArgumentError, "Either SCHEMA_REGISTRY_PASSWORD or SCHEMA_REGISTRY_PASSWORD_ENCRYPTED must be provided"
          end
        end
      end
    end
  end
end 

