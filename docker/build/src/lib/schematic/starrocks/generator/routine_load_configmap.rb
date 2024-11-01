# frozen_string_literal: true

module Schematic
  module Starrocks
    class Generator
      class RoutineLoadConfigMap < Schematic::Generator::GitOpsConfig
        def generate
          generate_gitops_dir
          render_cipher_configmap
          render_credentials_configmap
          render_database_configmap
          render_routine_load_configmap
        end

        def render_routine_load_configmap
          generate_by_template(
            File.join(dev_configmap_dir, 'routine-load-credentials.yaml'),
            File.join(routine_load_templates_dir, 'routine-load-credentials.yaml.erb'),
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

        def kafka_credentials
          {
            'KAFKA_BROKER_LIST' => ENV.fetch('KAFKA_BROKER_LIST', ''),
            'KAFKA_SECURITY_PROTOCOL' => ENV.fetch('KAFKA_SECURITY_PROTOCOL', ''),
            'KAFKA_SASL_MECHANISM' => ENV.fetch('KAFKA_SASL_MECHANISM', ''),
            'KAFKA_SASL_USERNAME' => ENV.fetch('KAFKA_SASL_USERNAME', ''),
            'KAFKA_SASL_PASSWORD' => ENV.fetch('KAFKA_SASL_PASSWORD', ''),
            'KAFKA_SASL_PASSWORD_ENCRYPTED' => ENV.fetch('KAFKA_SASL_PASSWORD_ENCRYPTED', ''),
            'KAFKA_SSL_VERIFY' => ENV.fetch('KAFKA_SSL_VERIFY', ''),
            'KAFKA_PARTITIONS' => ENV.fetch('KAFKA_PARTITIONS', ''),
            'KAFKA_OFFSET' => ENV.fetch('KAFKA_OFFSET', '')
          }
        end

        def schema_registry_credentials
          {
            'SCHEMA_REGISTRY_URL' => ENV.fetch('SCHEMA_REGISTRY_URL', ''),
            'SCHEMA_REGISTRY_USERNAME' => ENV.fetch('SCHEMA_REGISTRY_USERNAME', ''),
            'SCHEMA_REGISTRY_PASSWORD' => ENV.fetch('SCHEMA_REGISTRY_PASSWORD', ''),
            'SCHEMA_REGISTRY_PASSWORD_ENCRYPTED' => ENV.fetch('SCHEMA_REGISTRY_PASSWORD_ENCRYPTED', '')
          }
        end
      end
    end
  end
end 
