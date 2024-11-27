# frozen_string_literal: true

require 'dry-types'

module Schematic
  module Starrocks
    module Types
      include Dry.Types()

      # Basic Types
      StrictString = Types::Strict::String
      StrictSymbol = Types::Strict::Symbol
      StrictArray = Types::Strict::Array
      StrictHash = Types::Strict::Hash
      Any = Types::Any

      # Enums
      RoutineLoadOperation = Types::Strict::Symbol.enum(
        :create, :pause, :resume, :stop, :alter
      )

      # Complex Types
      KafkaSecurity = Types::Hash.schema(
        protocol: StrictString,
        mechanism: StrictString,
        username: StrictString,
        password: StrictString,
        ssl_verify: Types::Strict::Bool | Types::Strict::String
      )

      KafkaConfig = Types::Hash.schema(
        broker_list: StrictString,
        topic: StrictString.optional,
        partitions: StrictString,
        offset: StrictString,
        security: KafkaSecurity
      )

      SchemaRegistryAuth = Types::Hash.schema(
        username: StrictString,
        password: StrictString
      )

      SchemaRegistryConfig = Types::Hash.schema(
        url: StrictString,
        auth: SchemaRegistryAuth
      )

      # Properties that can be altered according to official doc
      ALTERABLE_PROPERTY_KEYS = %i[
        desired_concurrent_number
        max_error_number
        max_batch_interval
        max_batch_rows
        max_batch_size
        jsonpaths
        json_root
        strip_outer_array
        strict_mode
        timezone
      ].freeze

      # All properties (including non-alterable ones)
      RoutineLoadProperties = Types::Hash.schema(
        desired_concurrent_number: Types::String.optional,
        format: Types::String.optional,
        max_error_number: Types::String.optional,
        max_filter_ratio: Types::String.optional,
        max_batch_interval: Types::String.optional,
        max_batch_rows: Types::String.optional,
        task_consume_second: Types::String.optional,
        task_timeout_second: Types::String.optional,
        jsonpaths: Types::Array.of(Types::String).optional
      ).with_key_transform(&:to_sym)

      # Custom type for alterable properties that only checks keys
      AlterableProperties = Types::Hash.constructor do |hash|
        # Ensure all keys are in the allowed list
        extra_keys = hash.keys - ALTERABLE_PROPERTY_KEYS
        if extra_keys.any?
          raise Dry::Types::ConstraintError, "Properties #{extra_keys.join(', ')} are not alterable"
        end
        hash
      end

      # Base config that all operations need
      BaseRoutineLoadConfig = Types::Hash.schema(
        db_name: Types::String,
        table_name: Types::String,
        routine_name: Types::String,
        operation: RoutineLoadOperation
      )

      # Create needs everything
      CreateRoutineLoadConfig = BaseRoutineLoadConfig.schema(
        columns: Types::Array.of(Types::String),
        kafka: KafkaConfig,
        schema_registry: SchemaRegistryConfig,
        properties: RoutineLoadProperties
      )

      # Alter only needs base info and properties
      AlterRoutineLoadConfig = BaseRoutineLoadConfig.schema(
        properties: AlterableProperties
      )

      # Pause/Resume/Stop only need base info
      SimpleRoutineLoadConfig = BaseRoutineLoadConfig

      # Main type that dispatches to specific types
      RoutineLoadConfig = Types.Constructor(Types::Hash) do |input|
        case input[:operation]&.to_sym
        when :create
          CreateRoutineLoadConfig[input]
        when :alter
          AlterRoutineLoadConfig[input]
        when :pause, :resume, :stop
          SimpleRoutineLoadConfig[input]
        else
          raise Dry::Types::ConstraintError, "Invalid operation: #{input[:operation]}"
        end
      end

      # Shared LoadInfo type for both SQL and Config deployables
      RoutineLoadInfo = Types::Hash.schema(
        db_name: Types::StrictString,
        routine_name: Types::StrictString,
        operation: Types::StrictString,
        table_name: Types::StrictString | Types::Strict::Nil,
        version: Types::StrictString
      )
    end
  end
end 