# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class CreateRoutineLoadSqlTemplate < SqlTemplate
        def initialize(routine_name)
          super(routine_name, :create_routine_load)
        end

        # TODO: refactor to configurable, on init use ENV
        def create # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)

          # override the default_routine_name
          config.routine_name = name
          config = config.to_hash

          columns = config[:columns].join(', ')
          jsonpaths = config[:jsonpaths].map { |path| "\\\"#{path}\\\"" }.join(', ')

          <<~SQL
            USE #{config[:db]};

            STOP ROUTINE LOAD FOR #{config[:db]}.#{config[:routine_name]};

            CREATE ROUTINE LOAD #{config[:db]}.#{config[:routine_name]} ON #{config[:table]}
            COLUMNS TERMINATED BY ',',
            COLUMNS (#{columns})
            PROPERTIES
            (
              "desired_concurrent_number" = "1",
              "format" = "json",
              "jsonpaths" = "#{jsonpaths}"
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
