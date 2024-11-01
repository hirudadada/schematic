# frozen_string_literal: true

module Schematic
  module Starrocks
    module Providers
      class RoutineLoadConfigProvider
        # NOTE: https://docs.starrocks.io/docs/sql-reference/sql-statements/loading_unloading/routine_load/ALTER_ROUTINE_LOAD
        ALTERABLE_PROPERTIES = %i[
          desired_concurrent_number
          max_error_number
          max_batch_interval
          max_batch_rows
          max_batch_size
          jsonpaths
          json_root
          strip_outer_array
          strict_mode
          timezone
        ].freeze

        def prepare
          @db = fetch_env('DB_NAME', 'schematic')
          @kafka_broker_list = fetch_env('KAFKA_BROKER_LIST', 'broker1:9092,broker2:9092')
          @kafka_partitions = fetch_env('KAFKA_PARTITIONS', '0,1,2')
          @kafka_offset = fetch_env('KAFKA_OFFSET', 'OFFSET_BEGINNING')
          @kafka_sasl_username = fetch_env('KAFKA_SASL_USERNAME', 'default_username')
          @kafka_sasl_password = decrypt_kafka_password
          @schema_registry_url = fetch_env('SCHEMA_REGISTRY_URL', 'schema-registry:8081')
          @sink_username = fetch_env('SCHEMA_REGISTRY_USERNAME', 'sink_user')
          @sink_password = decrypt_schema_registry_password

          # Default properties from environment
          @properties = {
            desired_concurrent_number: fetch_env('ROUTINE_LOAD_CONCURRENT_NUMBER', '3'),
            format: 'json',
            # strip_outer_array: fetch_env('ROUTINE_LOAD_STRIP_OUTER_ARRAY', 'false'),
            # strict_mode: fetch_env('ROUTINE_LOAD_STRICT_MODE', 'true'),
            max_batch_interval: fetch_env('ROUTINE_LOAD_MAX_BATCH_INTERVAL', '10'),
            max_batch_rows: fetch_env('ROUTINE_LOAD_MAX_BATCH_ROWS', '200000'),
            # max_batch_size: fetch_env('ROUTINE_LOAD_MAX_BATCH_SIZE', '104857600'),
            max_error_number: fetch_env('ROUTINE_LOAD_MAX_ERROR_NUMBER', '1000'),
            max_filter_ratio: fetch_env('ROUTINE_LOAD_MAX_FILTER_RATIO', '1.0'),
            task_consume_second: fetch_env('ROUTINE_LOAD_TASK_CONSUME_SECOND', '15'),
            task_timeout_second: fetch_env('ROUTINE_LOAD_TASK_TIMEOUT_SECOND', '60'),
            # timezone: fetch_env('ROUTINE_LOAD_TIMEZONE', 'Asia/Macau')
          }

          validate!
          self
        end

        def db_name
          @db
        end

        def properties(operation = :create)
          return @properties if operation == :create

          if operation == :alter
            @properties.select { |k, _| ALTERABLE_PROPERTIES.include?(k) }
          else
            {}
          end
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
          {
            url: @schema_registry_url,
            auth: {
              username: @sink_username,
              password: @sink_password
            }
          }
        end

        def merge_properties(new_properties)
          @properties = @properties.merge(new_properties)
        end

        class << self
          def create
            new.prepare
          end
        end

        protected

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

