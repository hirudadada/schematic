# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadSqlTemplate < SqlTemplate
        include Defaults
        include Naming

        def initialize(table_name, operation = :create, provider = nil)
          routine_name = Naming.generate_routine_name(table_name)
          @provider = provider || Providers::RoutineLoadConfigProvider.create
          migration_name = Naming.generate_migration_name(table_name, @provider.db_name, operation)
          
          super(migration_name, :routine_load)
          @operation = operation
          @columns = DEFAULT_COLUMNS
          @table = table_name
          @routine_name = routine_name
        end

        def create
          case @operation.to_sym
          when :create
            create_routine_load_sql
          when :pause
            pause_routine_load_sql
          when :resume
            resume_routine_load_sql
          when :stop
            stop_routine_load_sql
          when :alter
            alter_routine_load_sql
          else
            raise ArgumentError, "Unsupported operation: #{@operation}"
          end
        end

        private

        def create_routine_load_sql
          properties = @provider.properties(:create)

          <<~SQL
            CREATE ROUTINE LOAD `#{@routine_name}` ON `#{@table}`
            COLUMNS TERMINATED BY ',',
            COLUMNS (#{@columns.join(', ')})
            PROPERTIES
            (
              #{format_properties(properties)}
            )
            FROM KAFKA
            (
              #{kafka_properties}
            );
          SQL
        end

        def pause_routine_load_sql
          "PAUSE ROUTINE LOAD FOR `#{@routine_name}`;"
        end

        def resume_routine_load_sql
          "RESUME ROUTINE LOAD FOR `#{@routine_name}`;"
        end

        def stop_routine_load_sql
          "STOP ROUTINE LOAD FOR `#{@routine_name}`;"
        end

        def alter_routine_load_sql
          <<~SQL
            ALTER ROUTINE LOAD FOR `#{@routine_name}`
            PROPERTIES
            (
              #{format_properties(@provider.properties(:alter))}
            );
          SQL
        end

        def kafka_properties
          [
            %("kafka_broker_list" = "{{KAFKA_BROKER_LIST}}"),
            %("kafka_topic" = "#{@table}"),
            %("property.security.protocol" = "{{KAFKA_SECURITY_PROTOCOL}}"),
            %("property.sasl.mechanism" = "{{KAFKA_SASL_MECHANISM}}"),
            %("property.sasl.username" = "{{KAFKA_SECURITY_USERNAME}}"),
            %("property.sasl.password" = "{{KAFKA_SECURITY_PASSWORD}}"),
            %("property.enable.ssl.certificate.verification" = "{{KAFKA_SSL_VERIFY}}"),
            %("confluent.schema.registry.url" = "{{SCHEMA_REGISTRY_URL}}"),
            %("property.basic.auth.credentials.source" = "USER_INFO"),
            %("kafka_partitions" = "{{KAFKA_PARTITIONS}}"),
            %("property.kafka_default_offsets" = "{{KAFKA_OFFSET}}")
          ].join(",\n  ")
        end

        def format_properties(properties)
          properties.map { |k, v| %("#{k}" = "#{format_value(v)}") }.join(",\n  ")
        end

        #{format_kafka_config(@provider.kafka_config, @provider.schema_registry_config)}
        # def format_kafka_config(kafka, schema_registry)
        #   [
        #     %("kafka_broker_list" = "#{kafka[:broker_list]}"),
        #     %("kafka_topic" = "#{@table}"),
        #     %("property.security.protocol" = "#{kafka[:security][:protocol]}"),
        #     %("property.sasl.mechanism" = "#{kafka[:security][:mechanism]}"),
        #     %("property.sasl.username" = "#{kafka[:security][:username]}"),
        #     %("property.sasl.password" = "#{kafka[:security][:password]}"),
        #     %("property.enable.ssl.certificate.verification" = "#{kafka[:security][:ssl_verify]}"),
        #     %("confluent.schema.registry.url" = "https://#{schema_registry[:auth][:username]}:#{schema_registry[:auth][:password]}@#{schema_registry[:url]}"),
        #     %("property.basic.auth.credentials.source" = "USER_INFO"),
        #     %("kafka_partitions" = "#{kafka[:partitions]}"),
        #     %("property.kafka_default_offsets" = "#{kafka[:offset]}")
        #   ].join(",\n  ")
        # end

        def format_value(value)
          case value
          when true, 'true' then 'true'
          when false, 'false' then 'false'
          when Array
            if value.all? { |v| v.start_with?('$.') }
              "[#{value.map { |path| "\\\"#{path}\\\"" }.join(', ')}]"
            else
              value.join(',')
            end
          else value.to_s
          end
        end
      end
    end
  end
end
