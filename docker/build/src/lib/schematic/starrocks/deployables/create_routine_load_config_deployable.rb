# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateRoutineLoadConfigDeployable < ConfigDeployable
        def initialize(name, data)
          super
          validate
        end

        # TODO: refactor this config[:routine_name] and name
        def deploy(client)
          client.run("DROP ROUTINE LOAD IF EXISTS #{config[:routine_name]}")
          client.run(generate_sql)
          puts "Deployed #{config[:routine_name]}"
        rescue Mysql2::Error => e
          puts "Error deploying #{config[:routine_name]}: #{e.message}"
        end

        protected

        def validate
          unless data.is_a?(Hash) && data[:name] && data[:task] && data[:config]
            raise ArgumentError, "Invalid data format for #{self.class.name}: #{data.inspect}"
          end

          unless task == :create_routine_load
            raise ArgumentError, "Unsupported task '#{data[:task]}' for #{self.class.name}"
          end
        end

        def generate_sql
          columns = data[:columns].join(', ')
          jsonpaths = data[:jsonpaths].map { |path| "\"#{path}\"" }.join(', ')

          <<~SQL
            USE #{data[:db]};

            CREATE ROUTINE LOAD #{data[:db]}.#{data[:routine_name]} ON #{data[:table]}
            COLUMNS TERMINATED BY ",",
            COLUMNS (#{columns})
            PROPERTIES
            (
              "desired_concurrent_number" = "1",
              "format" = "json",
              "jsonpaths" = "[#{jsonpaths}]"
            )
            FROM KAFKA
            (
              "kafka_broker_list" = "#{data[:kafka_broker_list]}",
              "kafka_topic" = "#{data[:kafka_topic]}",
              "property.security.protocol" = "SASL_SSL",
              "property.sasl.mechanism" = "PLAIN",
              "property.sasl.username" = "#{data[:sasl_username]}",
              "property.sasl.password" = "#{data[:sasl_password]}",
              "property.enable.ssl.certificate.verification" = "false",
              "confluent.schema.registry.url" = "https://#{data[:sink_username]}:#{data[:sink_password]}@#{data[:schema_registry_url]}",
              "property.basic.auth.credentials.source" = "USER_INFO",
              "kafka_partitions" = "0,1,2",
              "property.kafka_default_offsets" = "OFFSET_BEGINNING"
            )
          SQL
        end
      end
    end
  end
end

