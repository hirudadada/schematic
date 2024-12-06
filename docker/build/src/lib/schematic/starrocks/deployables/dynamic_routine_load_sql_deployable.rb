module Schematic
  module Starrocks
    module Deployables
      class DynamicRoutineLoadSqlDeployable < StaticRoutineLoadSqlDeployable
        DYNAMIC_ALLOWED_PATTERNS = [
          /\ASET\s+@sql\s*=\s*CONCAT\(/i,
          /\ASELECT\s+@sql\s+AS\s+final_sql/i
        ].freeze

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

        def parse_statements(sql)
          # For dynamic SQL, we treat the whole thing as one statement
          [sql]
        end

        def validate_statements!(statements)
          if create_operation?
            # For CREATE with dynamic SQL, validate CONCAT syntax
            statements.each do |stmt|
              unless DYNAMIC_ALLOWED_PATTERNS.all? { |pattern| stmt.match?(pattern) }
                raise Schematic::Starrocks::ValidationError, "Invalid dynamic SQL format"
              end
            end
          else
            # For other operations, use parent validation
            super
          end
        end

        def extract_create_statement(statements)
          if create_operation?
            # For dynamic SQL, we'll get the actual CREATE statement after execution
            statements.first
          else
            super
          end
        end

        def extract_load_info(sql)
          logger.debug("Extracting load info from SQL: #{sql}")
          
          operation = case sql
                     when /\ACREATE\s+ROUTINE\s+LOAD/i then 'create'
                     when /\APAUSE\s+ROUTINE\s+LOAD/i then 'pause'
                     when /\ARESUME\s+ROUTINE\s+LOAD/i then 'resume'
                     when /\ASTOP\s+ROUTINE\s+LOAD/i then 'stop'
                     when /\AALTER\s+ROUTINE\s+LOAD/i then 'alter'
                     else ''
                     end
          logger.debug("Detected operation: #{operation}")

          version = name.split('-').first
          logger.debug("Version from filename: #{version}")
          
          db_name = if sql =~ /(?:FROM|CREATE\s+ROUTINE\s+LOAD)\s+[`"]?([^`"\s.]+)[`"]?\./i
                      logger.debug("Found db_name in SQL: #{$1}")
                      $1
                    else
                      provider_db = provider.db_name
                      logger.debug("Using provider db_name: #{provider_db || 'schematic'}")
                      provider_db || 'schematic'
                    end

          routine_name = if sql =~ /(?:FOR|CREATE\s+ROUTINE\s+LOAD\s+(?:[^.]+\.)?)\s*[`"]?([^`"\s]+)[`"]?/i
                           logger.debug("Found routine_name in SQL: #{$1}")
                           $1
                         else
                           raise Schematic::Starrocks::ValidationError, "Cannot extract routine_name from SQL"
                         end

          table_name = if operation == 'create' && sql =~ /ON\s+[`"]?([^`"\s]+)[`"]?/i
                          logger.debug("Found table_name in SQL: #{$1}")
                          $1
                        else
                          name = routine_name.sub(/_rl$/, '')
                          logger.debug("Derived table_name from routine_name: #{name}")
                          name
                        end

          load_info = {
            db_name: db_name,
            routine_name: routine_name,
            operation: operation,
            table_name: table_name,
            version: version
          }
          logger.debug("Final load_info: #{load_info.inspect}")

          Types::RoutineLoadInfo[load_info]
        end

        def has_create_statement?(statements)
          create_operation?
        end

        def create_operation?
          data.match?(/SET\s+@sql\s*=\s*CONCAT.*CREATE\s+ROUTINE\s+LOAD/im)
        end

        private

        def provider
          @provider ||= options[:provider] || Providers::RoutineLoadConfigProvider.create
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

          variables.each do |name, value|
            client.run("SET @#{name} = '#{value}';")
          end
        end
      end
    end
  end
end 
