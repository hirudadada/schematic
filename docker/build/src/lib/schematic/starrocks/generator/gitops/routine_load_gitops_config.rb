# frozen_string_literal: true

module Schematic
  module Starrocks
    module Generator
      class RoutineLoadGitOpsConfig < Schematic::Generator::GitOpsConfig
        attr_reader :cluster_properties, :cluster_credentials

        def generate
          generate_gitops_dir
          render_cipher_configmap
          render_credentials_configmap
          render_database_configmap
          render_routine_load_configmap
          render_routine_load_properties_configmap
        end

        def render_routine_load_configmap
          generate_by_template(
            File.join(dev_configmap_dir, 'routine-load-credentials.yaml'),
            File.join(routine_load_templates_dir, 'routine-load-credentials.yaml.erb'),
            # File.join(routine_load_templates_dir, 'overlays/dev/configmap/routine-load-credentials.yaml.erb'),
            binding
          )
        end

        def render_routine_load_properties_configmap
          generate_by_template(
            File.join(dev_configmap_dir, 'routine-load-properties.yaml'),
            File.join(routine_load_templates_dir, 'routine-load-properties.yaml.erb'),
            # File.join(routine_load_templates_dir, 'overlays/dev/configmap/routine-load-properties.yaml.erb'),
            binding
          )
        end

        def routine_load_templates_dir
          @routine_load_templates_dir ||= init_routine_load_templates_dir
        end

        protected

        def init_routine_load_templates_dir
          (options[:routine_load_templates_dir] || default_routine_load_templates_dir)
        end

        def default_routine_load_templates_dir
          File.join(__dir__, 'templates', 'overlays', 'dev', 'configmap')
        end

        def kafka_sasl_password_encrypted
          ENV['KAFKA_SASL_PASSWORD'].nil? ||
          ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'].empty? ?
            Schematic::Cipher.new.encrypt(ENV['KAFKA_SASL_PASSWORD']) :
            ENV['KAFKA_SASL_PASSWORD_ENCRYPTED']
        end

        def schema_registry_password_encrypted
          ENV['SCHEMA_REGISTRY_PASSWORD'].nil? ||
          ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'].empty? ?
            Schematic::Cipher.new.encrypt(ENV['SCHEMA_REGISTRY_PASSWORD']) :
            ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED']
        end

        def cluster_credentials
          @cluster_credentials ||= {
            # Kafka Configuration
            'KAFKA_BROKER_LIST' => quote_value(ENV.fetch('KAFKA_BROKER_LIST', 'broker1:9092,broker2:9092')),
            'KAFKA_SECURITY_PROTOCOL' => quote_value(ENV.fetch('KAFKA_SECURITY_PROTOCOL', 'SASL_SSL')),
            'KAFKA_SASL_MECHANISM' => ENV.fetch('KAFKA_SASL_MECHANISM', 'PLAIN'),
            'KAFKA_SASL_USERNAME' => ENV.fetch('KAFKA_SASL_USERNAME', 'kafka_user'),
            # 'KAFKA_SASL_PASSWORD' => ENV.fetch('KAFKA_SASL_PASSWORD', ''),
            'KAFKA_SASL_PASSWORD_ENCRYPTED' => kafka_sasl_password_encrypted,
            'KAFKA_SSL_VERIFY' => ENV.fetch('KAFKA_SSL_VERIFY', 'false'),
            'KAFKA_PARTITIONS' => ENV.fetch('KAFKA_PARTITIONS', '0,1,2'),
            'KAFKA_OFFSET' => ENV.fetch('KAFKA_OFFSET', 'OFFSET_BEGINNING'),

            # Schema Registry Configuration
            'SCHEMA_REGISTRY_URL' => ENV.fetch('SCHEMA_REGISTRY_URL', 'schema-registry:8081'),
            'SCHEMA_REGISTRY_USERNAME' => ENV.fetch('SCHEMA_REGISTRY_USERNAME', 'registry_user'),
            # 'SCHEMA_REGISTRY_PASSWORD' => ENV.fetch('SCHEMA_REGISTRY_PASSWORD', ''),
            'SCHEMA_REGISTRY_PASSWORD_ENCRYPTED' => schema_registry_password_encrypted,
          }
        end

        def cluster_properties
          @cluster_properties ||= {
            # Routine Load Properties
            'ROUTINE_LOAD_CONCURRENT_NUMBER' => quote_value(ENV.fetch('ROUTINE_LOAD_CONCURRENT_NUMBER', '3')),
            'ROUTINE_LOAD_FORMAT' => quote_value(ENV.fetch('ROUTINE_LOAD_FORMAT', 'json')),
            'ROUTINE_LOAD_MAX_ERROR_NUMBER' => ENV.fetch('ROUTINE_LOAD_MAX_ERROR_NUMBER', '0'),
            'ROUTINE_LOAD_MAX_FILTER_RATIO' => ENV.fetch('ROUTINE_LOAD_MAX_FILTER_RATIO', '1.0'),
            'ROUTINE_LOAD_MAX_BATCH_INTERVAL' => ENV.fetch('ROUTINE_LOAD_MAX_BATCH_INTERVAL', '10'),
            'ROUTINE_LOAD_MAX_BATCH_ROWS' => ENV.fetch('ROUTINE_LOAD_MAX_BATCH_ROWS', '2000000'),
            'ROUTINE_LOAD_TASK_CONSUME_SECOND' => ENV.fetch('ROUTINE_LOAD_TASK_CONSUME_SECOND', '15'),
            'ROUTINE_LOAD_TASK_TIMEOUT_SECOND' => ENV.fetch('ROUTINE_LOAD_TASK_TIMEOUT_SECOND', '60'),

            # Deployment Configuration
            'MIGRATION_MODE' => ENV.fetch('MIGRATION_MODE', 'true'),
            'HYDRATE' => ENV.fetch('HYDRATE', 'true'),
            'DYNAMIC_SQL' => ENV.fetch('DYNAMIC_SQL', 'true'),
            'RESOURCE_DIR' => ENV.fetch('RESOURCE_DIR', 'db/starrocks'),
            'WORK_DIR' => ENV.fetch('WORK_DIR', nil),
            'LOG_LEVEL' => ENV.fetch('LOG_LEVEL', '1'),  # Use numeric level (1 = INFO)
            'SQL_LOG_LEVEL' => ENV.fetch('SQL_LOG_LEVEL', 'debug'),

            # Retry Configuration
            'RETRY_MAX_ATTEMPTS' => ENV.fetch('RETRY_MAX_ATTEMPTS', '3'),
            'RETRY_BASE_DELAY' => ENV.fetch('RETRY_BASE_DELAY', '2')
          }
        end

        private

        def quote_value(value)
          value.to_s.gsub('"', '\"')  # Escape any existing quotes
        end
      end
    end
  end
end 
