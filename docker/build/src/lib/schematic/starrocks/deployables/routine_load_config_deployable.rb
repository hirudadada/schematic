# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadConfigDeployable < ConfigDeployable
        module DeploymentMethods
          def check_and_stop_existing(client, db_name, routine_name)
            db_name = Types::StrictString[db_name]
            routine_name = Types::StrictString[routine_name]
            
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{routine_name}'").all

            if result.any?
              stop_sql = "STOP ROUTINE LOAD FOR `#{routine_name}`"
              logger.debug("Stopping existing routine load: #{stop_sql}") if logger.debug?
              client.run(stop_sql)
              sleep(2)
            end
          end

          def execute_operation(client, data)
            # For create operation, ensure topic is set
            if data[:operation].to_sym == :create
              data = data.merge(
                kafka: data[:kafka].merge(topic: data[:table])
              )
            end

            # Validate based on operation type
            data = case data[:operation].to_sym
                    when :create
                      Types::CreateRoutineLoadConfig[data]
                    when :alter
                      Types::AlterRoutineLoadConfig[data]
                    else
                      Types::SimpleRoutineLoadConfig[data]
                    end
            
            case data[:operation].to_sym
            when :create
              sql = create_routine_load_sql(data)
              client.run(sql)
            when :alter
              sql = alter_routine_load_sql(data)
              client.run(sql)
            when :pause, :resume, :stop
              # Simple operations only need routine_name
              client.run("#{data[:operation].to_s.upcase} ROUTINE LOAD FOR `#{data[:routine_name]}`;")
            else
              raise Schematic::Starrocks::RoutineLoadError, "Unsupported operation: #{data[:operation]}"
            end
          end

          def create_routine_load_sql(data)
            # Validate and ensure required fields
            data = data.merge(
              db: data[:db] || options[:provider]&.db_name,
              columns: data[:columns] || DEFAULT_COLUMNS,
              properties: data[:properties] || {}
            )
            
            # Validate with types
            data = Types::RoutineLoadConfig[data]
            
            columns = data[:columns].join(', ')

            <<~SQL
              CREATE ROUTINE LOAD `#{data[:db]}`.`#{data[:routine_name]}` ON `#{data[:table]}`
              COLUMNS TERMINATED BY ',',
              COLUMNS (#{columns})
              PROPERTIES
              (
                #{format_properties(data[:properties])}
              )
              FROM KAFKA
              (
                #{format_kafka_config(data[:kafka], data[:schema_registry])}
              );
            SQL
          end

          def alter_routine_load_sql(data)
            <<~SQL
              ALTER ROUTINE LOAD FOR `#{data[:routine_name]}`
              PROPERTIES
              (
                #{format_properties(data[:properties])}
              );
            SQL
          end

          def format_properties(properties)
            # Don't validate properties here - they should already be validated
            properties.map { |k, v| %("#{k}" = "#{format_value(v)}") }.join(",\n  ")
          end

          def format_kafka_config(kafka, schema_registry)
            kafka = Types::KafkaConfig[kafka]
            schema_registry = Types::SchemaRegistryConfig[schema_registry]
            
            [
              %("kafka_broker_list" = "#{kafka[:broker_list]}"),
              %("kafka_topic" = "#{kafka[:topic]}"),
              %("property.security.protocol" = "#{kafka[:security][:protocol]}"),
              %("property.sasl.mechanism" = "#{kafka[:security][:mechanism]}"),
              %("property.sasl.username" = "#{kafka[:security][:username]}"),
              %("property.sasl.password" = "#{kafka[:security][:password]}"),
              %("property.enable.ssl.certificate.verification" = "#{kafka[:security][:ssl_verify]}"),
              %("confluent.schema.registry.url" = "https://#{schema_registry[:auth][:username]}:#{schema_registry[:auth][:password]}@#{schema_registry[:url]}"),
              %("property.basic.auth.credentials.source" = "USER_INFO"),
              %("kafka_partitions" = "#{kafka[:partitions]}"),
              %("property.kafka_default_offsets" = "#{kafka[:offset]}")
            ].join(",\n  ")
          end

          def format_value(value)
            case value
            when true, 'true' then 'true'
            when false, 'false' then 'false'
            when Array
              # Handle jsonpaths array specially
              if value.all? { |v| v.start_with?('$.') }
                "[#{value.map { |path| "\\\"#{path}\\\"" }.join(', ')}]"
              else
                value.join(',')
              end
            else value.to_s
            end
          end

          def extract_load_info(data)
            version = name.split('-').first

            Types::RoutineLoadInfo[{
              db_name: data[:db] || options[:provider]&.db_name || 'schematic',
              routine_name: data[:routine_name],
              operation: data[:operation].to_s,
              table_name: data[:table],
              version: version
            }]
          end
        end

        include DeploymentMethods

        def deploy(client)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create
          
          client.transaction do
            client.run("USE #{provider.db_name};")
            
            load_info = extract_load_info(data)
            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, [build_sql], load_info)
          end
          logger.info("Deployed routine load operation: #{data[:operation]} for #{data[:routine_name]}")
        end

        private

        def build_sql
          case data[:operation].to_sym
          when :create
            create_routine_load_sql(data)
          when :alter
            alter_routine_load_sql(data)
          else
            "#{data[:operation].to_s.upcase} ROUTINE LOAD FOR `#{data[:routine_name]}`;"
          end
        end
      end
    end
  end
end
