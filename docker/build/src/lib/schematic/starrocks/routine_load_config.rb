# frozen_string_literal: true

module Schematic
  module Starrocks
    DEFAULT_ROUTINE_LOAD_CONFIG = {
      db: "schematic",
      table: "example_table",
      routine_name: "some_table_routine",
      operation: "create",  # can be: create, pause, resume, stop, alter
      columns: ["uid", "column_1", "column_2", "column_3", "column_4"],
      jsonpaths: ["$.uid", "$.column1", "$.column2", "$.column3", "$.column4"],
      kafka: {
        broker_list: "broker1:9092,broker2:9092,broker3:9092",
        topic: "some_topic",
        partitions: "0,1,2",
        offset: "OFFSET_BEGINNING",
        security: {
          protocol: "SASL_SSL",
          mechanism: "PLAIN",
          username: "sasl_username",
          password: "sasl_password",
          ssl_verify: false
        }
      },
      schema_registry: {
        url: "schema_registry_url",
        auth: {
          username: "sink_username",
          password: "sink_password"
        }
      },
      properties: {
        # Default properties
        desired_concurrent_number: "1",
        format: "json",
        # Additional properties ;)
        # strip_outer_array: false,
        # strict_mode: true,
        # max_batch_rows: "200000",
        # max_batch_size: "104857600",
        # max_error_number: "1000",
        # strict_mode: false,
        # timezone: "Asia/Macau",
        # load_parallelism: "1"
      }
    }.freeze

    class RoutineLoadConfig
      attr_accessor :name, :db, :table, :routine_name, :operation,
        :columns, :jsonpaths, :kafka, :schema_registry

      def initialize(opts = {})
        @name = opts[:name]
        @db = opts[:db]
        @table = opts[:table]
        @routine_name = opts[:routine_name]
        @operation = opts[:operation] || "create"
        @columns = opts[:columns]
        @jsonpaths = opts[:jsonpaths]
        @kafka = opts[:kafka]
        @schema_registry = opts[:schema_registry]
        @properties = opts[:properties] || {}
      end

      def properties=(props)
        @properties = props
      end

      def properties
        @properties
      end

      def add_property(key, value)
        @properties[key.to_sym] = value
      end

      def remove_property(key)
        @properties.delete(key.to_sym)
      end

      def to_hash
        {
          name: name,
          db: db,
          table: table,
          routine_name: routine_name,
          operation: operation,
          columns: columns,
          jsonpaths: jsonpaths,
          kafka: kafka,
          schema_registry: schema_registry,
          properties: properties
        }
      end

      def to_yaml
        to_hash.to_yaml
      end

      def properties_sql
        props = properties.map do |key, value|
          formatted_value = format_property_value(value)
          %("#{key}" = "#{formatted_value}")
        end
        props.join(",\n  ")
      end

      private

      def format_property_value(value)
        case value
        when true
          "true"
        when false
          "false"
        when Array
          value.join(',')
        else
          value.to_s
        end
      end
    end
  end
end
