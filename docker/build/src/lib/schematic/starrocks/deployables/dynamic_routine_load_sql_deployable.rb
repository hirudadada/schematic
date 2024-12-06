module Schematic
  module Starrocks
    module Deployables
      class DynamicRoutineLoadSqlDeployable < StaticRoutineLoadSqlDeployable
        def deploy(client)
          client.transaction do
            if create_operation?
              client.run("USE #{provider.db_name};")
              setup_variables(client)
              client.execute(data)
              result = client.fetch('SELECT @sql as final_sql').first
              final_sql = result[:final_sql]

              load_info = extract_load_info(final_sql)
              strategy = @strategy || Strategies.create(options)
              strategy.execute(client, [final_sql], load_info)
            else
              super
            end
          end
        end

        protected

        def provider
          @provider ||= options[:provider] || Providers::RoutineLoadConfigProvider.create
        end

        def create_operation?
          data.match?(/SET\s+@sql\s*=\s*CONCAT.*CREATE\s+ROUTINE\s+LOAD/im)
        end

        private

        def setup_variables(client)
          variables = {
            'kafka_broker_list' => provider.kafka_config[:broker_list],
            'kafka_security_protocol' => provider.kafka_config[:security][:protocol],
            'kafka_sasl_mechanism' => provider.kafka_config[:security][:mechanism],
            'kafka_security_username' => provider.kafka_config[:security][:username],
            'kafka_security_password' => provider.kafka_config[:security][:password],
            'kafka_ssl_verify' => provider.kafka_config[:security][:ssl_verify],
            'schema_registry_url' => provider.schema_registry_config[:url],
            'schema_registry_username' => provider.schema_registry_config[:auth][:username],
            'schema_registry_password' => provider.schema_registry_config[:auth][:password],
          }

          variables.each do |name, value|
            client.run("SET @#{name} = '#{value}';")
          end
        end
      end
    end
  end
end 
