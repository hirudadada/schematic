# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadConfigTemplate < ConfigTemplate
        include Defaults
        include Naming

        def initialize(table_name, operation = :create, provider = nil)
          @provider = provider || Providers::RoutineLoadConfigProvider.create
          routine_name = Naming.generate_routine_name(table_name)
          migration_name = Naming.generate_migration_name(table_name, operation)
          
          super(migration_name, :routine_load)
          @operation = operation
          @columns = DEFAULT_COLUMNS
          @table_name = table_name
          @routine_name = routine_name
          @db_name = @provider.db_name
        end

        def create
          case @operation.to_sym
          when :create
            create_config
          when :pause
            pause_config
          when :resume
            resume_config
          when :stop
            stop_config
          when :alter
            alter_config
          else
            raise ArgumentError, "Unsupported operation: #{@operation}"
          end
        end

        private

        def create_config
          {
            table_name: @table_name,
            routine_name: @routine_name,
            db_name: @db_name,
            operation: @operation,
            columns: @columns,
            kafka: {
              broker_list: '{{KAFKA_BROKER_LIST}}',
              topic: @table_name,
              partitions: '{{KAFKA_PARTITIONS}}',
              offset: '{{KAFKA_OFFSET}}',
              security: {
                protocol: '{{KAFKA_SECURITY_PROTOCOL}}',
                mechanism: '{{KAFKA_SASL_MECHANISM}}',
                username: '{{KAFKA_SASL_USERNAME}}',
                password: '{{KAFKA_SASL_PASSWORD}}',
                ssl_verify: '{{KAFKA_SSL_VERIFY}}'
              }
            },
            schema_registry: {
              url: '{{SCHEMA_REGISTRY_URL}}',
              auth: {
                username: '{{SCHEMA_REGISTRY_USERNAME}}',
                password: '{{SCHEMA_REGISTRY_PASSWORD}}'
              }
            },
            properties: init_properties
          }
        end

        def pause_config
          {
            table_name: @table_name,
            routine_name: @routine_name,
            db_name: @db_name,
            operation: @operation
          }
        end

        def resume_config
          {
            table_name: @table_name,
            routine_name: @routine_name,
            db_name: @db_name,
            operation: @operation
          }
        end

        def stop_config
          {
            table_name: @table_name,
            routine_name: @routine_name,
            db_name: @db_name,
            operation: @operation
          }
        end

        def alter_config
          {
            table_name: @table_name,
            routine_name: @routine_name,
            db_name: @db_name,
            operation: @operation,
            properties: DEFAULT_PROPERTIES.select { |k, _| ALTERABLE_PROPERTIES.include?(k) }
          }
        end
      end
    end
  end
end
