# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      DEFAULT_ROUTINE_LOAD_CONFIG = {
        "db": "schematic",
        "table": "testing",
        "routine_name": "some_table_routine",
        "columns": ["uid", "column_1", "column_2", "column_3", "column_4"],
        "jsonpaths": ["\$.uid", "\$.column1", "\$.column2", "\$.column3", "\$.column4"],
        "kafka_broker_list": "broker1:9092,broker2:9092,broker3:9092",
        "kafka_topic": "some_topic",
        "sasl_username": "sasl_username",
        "sasl_password": "sasl_password",
        "schema_registry_url": "schema_registry_url",
        "sink_username": "sink_username",
        "sink_password": "sink_password"
      }.freeze

      class RoutineLoadConfig
        attr_accessor :name, :db, :table, :routine_name, :columns, :jsonpaths,
          :kafka_broker_list, :kafka_topic, :sasl_username, :sasl_password,
          :schema_registry_url, :sink_username, :sink_password

        def initialize(opts = {})
          @name = opts[:name]
          @db = opts[:db]
          @table = opts[:table]
          @routine_name = opts[:routine_name]
          @columns = opts[:columns]
          @jsonpaths = opts[:jsonpaths]
          @kafka_broker_list = opts[:kafka_broker_list]
          @kafka_topic = opts[:kafka_topic]
          @sasl_username = opts[:sasl_username]
          @sasl_password = opts[:sasl_password]
          @schema_registry_url = opts[:schema_registry_url]
          @sink_username = opts[:sink_username]
          @sink_password = opts[:sink_password]
        end

        def to_hash
          {
            name: name,
            db: db,
            table: table,
            routine_name: routine_name,
            columns: columns,
            jsonpaths: jsonpaths,
            kafka_broker_list: kafka_broker_list,
            kafka_topic: kafka_topic,
            sasl_username: sasl_username,
            sasl_password: sasl_password,
            schema_registry_url: schema_registry_url,
            sink_username: sink_username,
            sink_password: sink_password
          }
        end
      end
    end
  end
end

