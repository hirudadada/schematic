# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadConfigDeployable < ConfigDeployable
        module DeploymentMethods
          def check_and_stop_existing(client, db_name, load_name)
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{load_name}'").all

            if result.any?
              stop_sql = "STOP ROUTINE LOAD FOR `#{load_name}`"
              logger.debug("Stopping existing routine load: #{stop_sql}") if logger.debug?
              client.run(stop_sql)
              sleep(2)
            end
          end

          def execute_operation(client, config)
            case config[:operation].to_sym
            when :create
              create_routine_load(client, config)
            when :pause
              client.run("PAUSE ROUTINE LOAD FOR `#{config[:routine_name]}`;")
            when :resume
              client.run("RESUME ROUTINE LOAD FOR `#{config[:routine_name]}`;")
            when :stop
              client.run("STOP ROUTINE LOAD FOR `#{config[:routine_name]}`;")
            when :alter
              alter_routine_load(client, config)
            else
              raise DeploymentError, "Unsupported operation: #{config[:operation]}"
            end
          end

          def create_routine_load(client, config)
            columns = config[:columns].join(', ')
            jsonpaths = config[:jsonpaths].map { |path| "\\\"#{path}\\\"" }.join(', ')

            sql = <<~SQL
              CREATE ROUTINE LOAD #{config[:db]}.#{config[:routine_name]} ON #{config[:table]}
              COLUMNS TERMINATED BY ',',
              COLUMNS (#{columns})
              PROPERTIES
              (
                #{format_properties(config[:properties])},
                "jsonpaths" = "[#{jsonpaths}]"
              )
              FROM KAFKA
              (
                #{format_kafka_config(config[:kafka], config[:schema_registry])}
              );
            SQL

            logger.debug("Creating routine load: #{sql}") if logger.debug?
            client.run(sql)
          end

          def alter_routine_load(client, config)
            sql = <<~SQL
              ALTER ROUTINE LOAD FOR `#{config[:routine_name]}`
              PROPERTIES
              (
                #{format_properties(config[:properties])}
              );
            SQL

            logger.debug("Altering routine load: #{sql}") if logger.debug?
            client.run(sql)
          end

          def format_properties(properties)
            properties.map { |k, v| %("#{k}" = "#{format_value(v)}") }.join(",\n  ")
          end

          def format_kafka_config(kafka, schema_registry)
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
            when Array then value.join(',')
            else value.to_s
            end
          end
        end

        include DeploymentMethods

        def deploy(client)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create

          client.transaction do
            client.run("USE #{provider.db_name};")

            if data[:operation].to_sym == :create
              check_and_stop_existing(client, provider.db_name, data[:routine_name])
            end

            execute_operation(client, data)
          end
          logger.info("Deployed routine load operation: #{data[:operation]} for #{data[:routine_name]}")
        end
      end
    end
  end
end
