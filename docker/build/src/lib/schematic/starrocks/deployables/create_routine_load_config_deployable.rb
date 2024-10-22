# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateRoutineLoadConfigDeployable < ConfigDeployable
        def deploy(client)
          client.transaction do
            client.run("USE #{config[:db]};")
            stop_existing_routine_load(client)
            client.run(generate_sql)
          end
          puts "Deployed #{config[:routine_name]}"
        end

        protected

        def validate_data
          raise ArgumentError, "Invalid data format for #{self.class.name}: #{data.inspect}" unless valid_data?

          raise ArgumentError, "Unsupported task '#{data[:task]}' for #{self.class.name}" unless data[:task] == :create_routine_load
        end

        def valid_data?
          data.is_a?(Hash) &&
            data[:name] &&
            data[:task] &&
            data[:config].is_a?(Hash) &&
            data[:config][:db] &&
            data[:config][:table] &&
            data[:config][:routine_name] &&
            data[:config][:columns].is_a?(Array) &&
            data[:config][:jsonpaths].is_a?(Array)
        end

        def stop_existing_routine_load(client)
          result = client.fetch("SHOW ROUTINE LOAD WHERE NAME = '#{config[:routine_name]}';").all
          if result.any?
            client.fetch("STOP ROUTINE LOAD FOR #{config[:db]}.#{config[:routine_name]};").all
          end
        end

        def generate_sql
          columns = config[:columns].join(', ')
          jsonpaths = config[:jsonpaths].map { |path| "\\\"#{path}\\\"" }.join(', ')

          <<~SQL
            CREATE ROUTINE LOAD #{config[:db]}.#{config[:routine_name]} ON #{config[:table]}
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
              "kafka_broker_list" = "#{config[:kafka_broker_list]}",
              "kafka_topic" = "#{config[:kafka_topic]}",
              "property.security.protocol" = "SASL_SSL",
              "property.sasl.mechanism" = "PLAIN",
              "property.sasl.username" = "#{config[:sasl_username]}",
              "property.sasl.password" = "#{config[:sasl_password]}",
              "property.enable.ssl.certificate.verification" = "false",
              "confluent.schema.registry.url" = "https://#{config[:sink_username]}:#{config[:sink_password]}@#{config[:schema_registry_url]}",
              "property.basic.auth.credentials.source" = "USER_INFO",
              "kafka_partitions" = "0,1,2",
              "property.kafka_default_offsets" = "OFFSET_BEGINNING"
            );
          SQL
        end
      end
    end
  end
end
