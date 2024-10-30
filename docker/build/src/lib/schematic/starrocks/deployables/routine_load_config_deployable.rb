# frozen_string_literal: true

require 'yaml'

module Schematic
  module Starrocks
    module Deployables
      class RoutineLoadConfigDeployable < ConfigDeployable
        def deploy(client)
          config = RoutineLoadConfig.new(data)
          client.transaction do
            client.run("USE #{config.db};")

            if config.operation.to_sym == :create
              check_and_stop_existing(client, config.db, config.routine_name)
            end

            execute_operation(client, config)
          end
          logger.info("Deployed routine load operation: #{config.operation} for #{config.routine_name}")
        end

        private

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
          case config.operation.to_sym
          when :create
            create_routine_load(client, config)
          when :pause
            client.run("PAUSE ROUTINE LOAD FOR `#{config.routine_name}`;")
          when :resume
            client.run("RESUME ROUTINE LOAD FOR `#{config.routine_name}`;")
          when :stop
            client.run("STOP ROUTINE LOAD FOR `#{config.routine_name}`;")
          when :alter
            alter_routine_load(client, config)
          else
            raise DeploymentError, "Unsupported operation: #{config.operation}"
          end
        end

        def create_routine_load(client, config)
          columns = config.columns.join(', ')
          jsonpaths = config.jsonpaths.map { |path| "\\\"#{path}\\\"" }.join(', ')

          sql = <<~SQL
            CREATE ROUTINE LOAD #{config.db}.#{config.routine_name} ON #{config.table}
            COLUMNS TERMINATED BY ',',
            COLUMNS (#{columns})
            PROPERTIES
            (
              #{config.properties_sql},
              "jsonpaths" = "[#{jsonpaths}]"
            )
            FROM KAFKA
            (
              "kafka_broker_list" = "#{config.kafka[:broker_list]}",
              "kafka_topic" = "#{config.kafka[:topic]}",
              "property.security.protocol" = "#{config.kafka[:security][:protocol]}",
              "property.sasl.mechanism" = "#{config.kafka[:security][:mechanism]}",
              "property.sasl.username" = "#{config.kafka[:security][:username]}",
              "property.sasl.password" = "#{config.kafka[:security][:password]}",
              "property.enable.ssl.certificate.verification" = "#{config.kafka[:security][:ssl_verify]}",
              "confluent.schema.registry.url" = "https://#{config.schema_registry[:auth][:username]}:#{config.schema_registry[:auth][:password]}@#{config.schema_registry[:url]}",
              "property.basic.auth.credentials.source" = "USER_INFO",
              "kafka_partitions" = "#{config.kafka[:partitions]}",
              "property.kafka_default_offsets" = "#{config.kafka[:offset]}"
            );
          SQL

          logger.debug("Creating routine load: #{sql}") if logger.debug?
          client.run(sql)
        end

        def alter_routine_load(client, config)
          sql = <<~SQL
            ALTER ROUTINE LOAD FOR `#{config.routine_name}`
            PROPERTIES
            (
              #{config.properties_sql}
            );
          SQL

          logger.debug("Altering routine load: #{sql}") if logger.debug?
          client.run(sql)
        end
      end
    end
  end
end
