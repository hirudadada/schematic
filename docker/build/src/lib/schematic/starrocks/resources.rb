# frozen_string_literal: true

module Schematic
  module Starrocks
    class BaseResource
      attr_reader :name, :type

      def initialize(name, type)
        @name = name
        @type = type
      end

      def deploy(deployer)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end

    class SQLResource < BaseResource
      attr_reader :sql

      def initialize(name, sql)
        super(name, :sql)
        @sql = sql
      end

      def deploy(deployer)
      end
    end
  end
end

# def generate_routine_load_sql(config)
#   columns = config[:columns].join(', ')
#   jsonpaths = config[:jsonpaths].map { |path| "\"#{path}\"" }.join(', ')
#
#   sql = <<~SQL
#     USE #{config[:db]};
#     CREATE ROUTINE LOAD #{config[:db]}.#{config[:routine_name]} ON #{config[:table]}
#     COLUMNS TERMINATED BY ",",
#     COLUMNS (#{columns})
#     PROPERTIES
#     (
#       "desired_concurrent_number" = "1",
#       "format" = "json",
#       "jsonpaths" = "[#{jsonpaths}]"
#     )
#     FROM KAFKA
#     (
#       "kafka_broker_list" = "#{config[:kafka_broker_list]}",
#       "kafka_topic" = "#{config[:kafka_topic]}",
#       "property.security.protocol" = "SASL_SSL",
#       "property.sasl.mechanism" = "PLAIN",
#       "property.sasl.username" = "#{config[:sasl_username]}",
#       "property.sasl.password" = "#{config[:sasl_password]}",
#       "property.enable.ssl.certificate.verification" = "false",
#       "confluent.schema.registry.url" = "https://#{config[:sink_username]}:#{config[:sink_password]}@#{config[:schema_registry_url]}",
#       "property.basic.auth.credentials.source" = "USER_INFO",
#       "kafka_partitions" = "0,1,2",
#       "property.kafka_default_offsets" = "OFFSET_BEGINNING"
#     )
#   SQL
#
#   sql
# end
