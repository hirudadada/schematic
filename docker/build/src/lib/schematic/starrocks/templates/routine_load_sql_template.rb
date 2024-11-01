# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadSqlTemplate < SqlTemplate
        DEFAULT_COLUMNS = ['uid', 'column1', 'column2', 'column3'].freeze
        DEFAULT_JSONPATHS = ['$.uid', '$.column1', '$.column2', '$.column3'].freeze

        def initialize(table_name, operation = :create, provider = nil)
          @operation = operation
          @provider = provider || Providers::RoutineLoadConfigProvider.create
          @columns = DEFAULT_COLUMNS
          @jsonpaths = DEFAULT_JSONPATHS
          @table = table_name
          super(generate_routine_name(table_name), :routine_load)
        end

        def create
          case @operation
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
            raise ArgumentError, "Unknown operation: #{@operation}"
          end
        end

        private

        def generate_routine_name(table_name)
          timestamp = Time.now.strftime('%Y%m%d')
          "#{@provider.db_name}_#{table_name}_routine_load_#{timestamp}"
        end

        def create_routine_load_sql
          <<~SQL
            USE #{@provider.db_name};

            CREATE ROUTINE LOAD #{@provider.db_name}.#{name} ON #{@table}
            COLUMNS TERMINATED BY ',',
            COLUMNS (#{@columns.join(', ')})
            PROPERTIES
            (
              #{format_properties},
              "jsonpaths" = "[#{format_jsonpaths}]"
            )
            FROM KAFKA
            (
              #{format_kafka_config}
            );
          SQL
        end

        def pause_routine_load_sql
          <<~SQL
            USE #{@provider.db_name};

            PAUSE ROUTINE LOAD FOR `#{name}`;
          SQL
        end

        def resume_routine_load_sql
          <<~SQL
            USE #{@provider.db_name};

            RESUME ROUTINE LOAD FOR `#{name}`;
          SQL
        end

        def stop_routine_load_sql
          <<~SQL
            USE #{@provider.db_name};

            STOP ROUTINE LOAD FOR `#{name}`;
          SQL
        end

        def alter_routine_load_sql
          <<~SQL
            USE #{@provider.db_name};
            ALTER ROUTINE LOAD FOR `#{name}`
            PROPERTIES
            (
              #{format_properties(:alter)}
            );
          SQL
        end

        def format_properties(operation = :create)
          @provider.properties(operation).map { |k, v| %("#{k}" = "#{format_value(v)}") }.join(",\n  ")
        end

        def format_jsonpaths
          @jsonpaths.map { |path| "\\\"#{path}\\\"" }.join(', ')
        end

        def format_kafka_config
          [
            %("kafka_broker_list" = "{{KAFKA_BROKER_LIST}}"),
            %("kafka_topic" = "#{@table}"),  # Table-specific
            %("property.security.protocol" = "{{KAFKA_SECURITY_PROTOCOL}}"),
            %("property.sasl.mechanism" = "{{KAFKA_SASL_MECHANISM}}"),
            %("property.sasl.username" = "{{KAFKA_SASL_USERNAME}}"),
            %("property.sasl.password" = "{{KAFKA_SASL_PASSWORD}}"),
            %("property.enable.ssl.certificate.verification" = "{{KAFKA_SSL_VERIFY}}"),
            %("confluent.schema.registry.url" = "https://{{SCHEMA_REGISTRY_USERNAME}}:{{SCHEMA_REGISTRY_PASSWORD}}@{{SCHEMA_REGISTRY_URL}}"),
            %("property.basic.auth.credentials.source" = "USER_INFO"),
            %("kafka_partitions" = "{{KAFKA_PARTITIONS}}"),
            %("property.kafka_default_offsets" = "{{KAFKA_OFFSET}}")
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
    end
  end
end 
