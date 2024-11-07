# frozen_string_literal: true

module Schematic
  module Starrocks
    module Generator
      class RoutineLoadGitOpsConfig < Schematic::Generator::GitOpsConfig
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
          creds = {
            'KAFKA_BROKER_LIST' => ENV.fetch('KAFKA_BROKER_LIST', ''),
            'KAFKA_SECURITY_PROTOCOL' => ENV.fetch('KAFKA_SECURITY_PROTOCOL', ''),
            'KAFKA_SASL_MECHANISM' => ENV.fetch('KAFKA_SASL_MECHANISM', ''),
            'KAFKA_SASL_USERNAME' => ENV.fetch('KAFKA_SASL_USERNAME', ''),
            'KAFKA_SSL_VERIFY' => ENV.fetch('KAFKA_SSL_VERIFY', ''),
            'KAFKA_PARTITIONS' => ENV.fetch('KAFKA_PARTITIONS', ''),
            'KAFKA_OFFSET' => ENV.fetch('KAFKA_OFFSET', '')
          }

          if ENV['KAFKA_SASL_PASSWORD_ENCRYPTED']
            creds['KAFKA_SASL_PASSWORD_ENCRYPTED'] = ENV['KAFKA_SASL_PASSWORD_ENCRYPTED']
          else
            creds['KAFKA_SASL_PASSWORD'] = ENV['KAFKA_SASL_PASSWORD']
          end

          creds
        end

        def schema_registry_credentials
          creds = {
            'SCHEMA_REGISTRY_URL' => ENV.fetch('SCHEMA_REGISTRY_URL', ''),
            'SCHEMA_REGISTRY_USERNAME' => ENV.fetch('SCHEMA_REGISTRY_USERNAME', '')
          }

          if ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED']
            creds['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'] = ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED']
          else
            creds['SCHEMA_REGISTRY_PASSWORD'] = ENV['SCHEMA_REGISTRY_PASSWORD']
          end

          creds
        end

        def routine_load_properties
          {
            'ROUTINE_LOAD_CONCURRENT_NUMBER' => ENV.fetch('ROUTINE_LOAD_CONCURRENT_NUMBER', '3'),
            'ROUTINE_LOAD_FORMAT' => ENV.fetch('ROUTINE_LOAD_FORMAT', 'json'),
            'ROUTINE_LOAD_MAX_ERROR_NUMBER' => ENV.fetch('ROUTINE_LOAD_MAX_ERROR_NUMBER', '0'),
            'ROUTINE_LOAD_MAX_FILTER_RATIO' => ENV.fetch('ROUTINE_LOAD_MAX_FILTER_RATIO', '1.0'),
            'ROUTINE_LOAD_MAX_BATCH_INTERVAL' => ENV.fetch('ROUTINE_LOAD_MAX_BATCH_INTERVAL', '10'),
            'ROUTINE_LOAD_MAX_BATCH_ROWS' => ENV.fetch('ROUTINE_LOAD_MAX_BATCH_ROWS', '2000000'),
            'ROUTINE_LOAD_TASK_CONSUME_SECOND' => ENV.fetch('ROUTINE_LOAD_TASK_CONSUME_SECOND', '15'),
            'ROUTINE_LOAD_TASK_TIMEOUT_SECOND' => ENV.fetch('ROUTINE_LOAD_TASK_TIMEOUT_SECOND', '60')
          }
        end
      end
    end
  end
end 
