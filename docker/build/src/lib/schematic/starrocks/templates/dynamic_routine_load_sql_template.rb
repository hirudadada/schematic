  module Schematic
  module Starrocks
    module Templates
      class DynamicRoutineLoadSqlTemplate < RoutineLoadSqlTemplate
        protected

        def format_properties(properties)
          properties.map.with_index do |(k, v), i|
            last = i == properties.length - 1
            %('"#{k}"="#{format_value(v)}"#{last ? "" : ","} ')
          end.join(",\n    ")
        end

        def format_value(value)
          case value
          when true, 'true' then 'true'
          when false, 'false' then 'false'
          when Array
            if value.all? { |v| v.start_with?('$.') }
              "[#{value.map { |path| "\\\\\"#{path}\\\\\"" }.join(', ')}]"
            else
              value.join(',')
            end
          else value.to_s
          end
        end

        def kafka_properties
          [
            %('"kafka_broker_list"="', @kafka_broker_list, '", '),
            %('"kafka_topic"="#{@table}", '),
            %('"property.security.protocol"="', @kafka_security_protocol, '", '),
            %('"property.sasl.mechanism"="', @kafka_sasl_mechanism, '", '),
            %('"property.sasl.username"="', @kafka_security_username, '", '),
            %('"property.sasl.password"="', @kafka_security_password, '", '),
            %('"property.enable.ssl.certificate.verification"="', @kafka_ssl_verify, '", '),
            %('"confluent.schema.registry.url"="https://', @schema_registry_username, ':', @schema_registry_password, '\\@', @schema_registry_url, '", '),
            %('"property.basic.auth.credentials.source"="USER_INFO", '),
            %('"kafka_partitions"="#{@provider.kafka_config[:partitions]}", '),
            %('"property.kafka_default_offsets"="#{@provider.kafka_config[:offset]}" ')
          ].join(",\n    ")
        end

        def create_routine_load_sql
          properties = @provider.properties(:create)
          @logger.debug("Provider db_name: #{@provider.db_name}")

          sql = <<~SQL
            SET @sql = CONCAT(
              'CREATE ROUTINE LOAD `#{@routine_name}` ON `#{@table}` ',
              'COLUMNS TERMINATED BY '','', ',
              'COLUMNS (#{@columns.join(', ')}) ',
              'PROPERTIES ',
              '( ',
                #{format_properties(properties)} ,
              ') ',
              'FROM KAFKA ',
              '( ',
                #{kafka_properties} ,
              ');'
            );
          SQL

          @logger.debug("Generated SQL: #{sql}")
          sql
        end
      end
    end
  end
end 
