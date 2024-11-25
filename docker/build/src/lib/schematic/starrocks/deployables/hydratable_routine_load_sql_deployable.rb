# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadSqlDeployable < HydratableDeployableResource
        include RoutineLoadSqlDeployable::DeploymentMethods

        def deploy(client)
          hydrated_sql = Types::StrictString[hydrate_placeholders(data)]
          
          client.transaction do
            statements = parse_statements(hydrated_sql)
            validate_statements!(statements)

            load_info = if has_create_statement?(statements)
                          create_stmt = extract_create_statement(statements)
                          extract_load_info(create_stmt)
                        else
                          extract_load_info(statements.first)
                        end
        
            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, statements, load_info)
          end
          logger.info("Deployed #{name}")
        end
      end
    end
  end
end 
