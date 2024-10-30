# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class RoutineLoadSqlTemplate < SqlTemplate
        def initialize(routine_name, operation = :create)
          super(routine_name, :routine_load)
          @operation = operation
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

        def create_routine_load_sql
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          config = config.to_hash

          columns = config[:columns].join(', ')
          jsonpaths = config[:jsonpaths].map { |path| "\\\"#{path}\\\"" }.join(', ')

          <<~SQL
            USE #{config[:db]};

            CREATE ROUTINE LOAD #{config[:db]}.#{config[:routine_name]} ON #{config[:table]}
            COLUMNS TERMINATED BY ',',
            COLUMNS (#{columns})
            PROPERTIES
            (
              #{config[:properties].map { |k, v| %("#{k}" = "#{v}") }.join(",\n  ")},
              "jsonpaths" = "[#{jsonpaths}]"
            )
            FROM KAFKA
            (
              "kafka_broker_list" = "#{config[:kafka][:broker_list]}",
              "kafka_topic" = "#{config[:kafka][:topic]}",
              "property.security.protocol" = "#{config[:kafka][:security][:protocol]}",
              "property.sasl.mechanism" = "#{config[:kafka][:security][:mechanism]}",
              "property.sasl.username" = "#{config[:kafka][:security][:username]}",
              "property.sasl.password" = "#{config[:kafka][:security][:password]}",
              "property.enable.ssl.certificate.verification" = "#{config[:kafka][:security][:ssl_verify]}",
              "confluent.schema.registry.url" = "https://#{config[:schema_registry][:auth][:username]}:#{config[:schema_registry][:auth][:password]}@#{config[:schema_registry][:url]}",
              "property.basic.auth.credentials.source" = "USER_INFO",
              "kafka_partitions" = "#{config[:kafka][:partitions]}",
              "property.kafka_default_offsets" = "#{config[:kafka][:offset]}"
            );
          SQL
        end

        def pause_routine_load_sql
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          
          <<~SQL
            USE #{config.db};

            PAUSE ROUTINE LOAD FOR `#{config.routine_name}`;
          SQL
        end

        def resume_routine_load_sql
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          
          <<~SQL
            USE #{config.db};

            RESUME ROUTINE LOAD FOR `#{config.routine_name}`;
          SQL
        end

        def stop_routine_load_sql
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          
          <<~SQL
            USE #{config.db};

            STOP ROUTINE LOAD FOR `#{config.routine_name}`;
          SQL
        end

        def alter_routine_load_sql
          config = RoutineLoadConfig.new(DEFAULT_ROUTINE_LOAD_CONFIG)
          config.routine_name = name
          
          <<~SQL
            USE #{config.db};

            ALTER ROUTINE LOAD FOR `#{config.routine_name}`
            PROPERTIES
            (
              #{config.properties_sql}
            );
          SQL
        end
      end
    end
  end
end 
