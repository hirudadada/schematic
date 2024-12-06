module Schematic
  module Starrocks
    module Deployables
      class DynamicRoutineLoadSqlDeployable < RoutineLoadSqlDeployable
        def deploy(client)
          client.transaction do
            # Set up variables first
            client.run("USE #{provider.db_name};")

            statements = validate_statements!([data])

            # TODO: use system variables after upgrade to 3.7
            setup_variables(client)

            client.execute(data)

            result = client.fetch('SELECT @sql as final_sql').first
            final_sql = result[:final_sql]

            # Execute the final SQL
            load_info = extract_load_info(final_sql)
            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, [final_sql], load_info)
          end
        end

        protected

        DYNAMIC_ALLOWED_PATTERNS = [
          /\ASET\s+@[A-Za-z_][A-Za-z0-9_]*\s*=\s*'[^']*'/i,  # SET @var = 'value'
          /\ASET\s+@sql\s*=\s*CONCAT\(/i,                     # SET @sql = CONCAT(
          /\ASELECT\s+@sql\s+AS\s+final_sql/i                # SELECT @sql AS final_sql
        ].freeze

        def validate_statements!(statements)
          statements.each do |stmt|
            unless DYNAMIC_ALLOWED_PATTERNS.any? { |pattern| stmt.match?(pattern) }
              raise Schematic::Starrocks::ValidationError, "Invalid dynamic SQL command: #{stmt}"
            end
          end
        end

        def provider
          @provider = options[:provider] || Providers::RoutineLoadConfigProvider.create
        end

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

          # Set each variable
          variables.each do |name, value|
            client.run("SET @#{name} = '#{value}';")
          end
        end
      end
    end
  end
end 
