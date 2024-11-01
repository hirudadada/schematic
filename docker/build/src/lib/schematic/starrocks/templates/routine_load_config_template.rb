# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadConfigTemplate < ConfigTemplate
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
            create_config
          when :pause, :resume, :stop
            state_change_config
          when :alter
            alter_config
          else
            raise ArgumentError, "Unsupported operation: #{@operation}"
          end
        end

        private

        def generate_routine_name(table_name)
          timestamp = Time.now.strftime('%Y%m%d')
          "#{@provider.db_name}_#{table_name}_routine_load_#{timestamp}"
        end

        def create_config
          {
            db: @provider.db_name,
            table: @table,
            routine_name: name,
            operation: @operation.to_s,
            columns: @columns,
            jsonpaths: @jsonpaths,
            kafka: {
              broker_list: "{{KAFKA_BROKER_LIST}}",
              topic: @table,  # Table-specific
              partitions: "{{KAFKA_PARTITIONS}}",
              offset: "{{KAFKA_OFFSET}}",
              security: {
                protocol: "{{KAFKA_SECURITY_PROTOCOL}}",
                mechanism: "{{KAFKA_SASL_MECHANISM}}",
                username: "{{KAFKA_SASL_USERNAME}}",
                password: "{{KAFKA_SASL_PASSWORD}}",
                ssl_verify: "{{KAFKA_SSL_VERIFY}}"
              }
            },
            schema_registry: {
              url: "{{SCHEMA_REGISTRY_URL}}",
              auth: {
                username: "{{SCHEMA_REGISTRY_USERNAME}}",
                password: "{{SCHEMA_REGISTRY_PASSWORD}}"
              }
            },
            properties: @provider.properties
          }.to_yaml
        end

        def state_change_config
          {
            db: @provider.db_name,
            routine_name: name,
            operation: @operation.to_s
          }.to_yaml
        end

        def alter_config
          {
            db: @provider.db_name,
            routine_name: name,
            operation: @operation.to_s,
            properties: @provider.properties(:alter)
          }.to_yaml
        end
      end
    end
  end
end 
