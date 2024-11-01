module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadSqlDeployable < HydratableDeployableResource
        include RoutineLoadSqlDeployable::DeploymentMethods

        def deploy(client)
          hydrated_sql = hydrate_placeholders(data)
          client.transaction do
            statements = parse_statements(hydrated_sql)
            validate_statements!(statements)

            if has_create_statement?(statements)
              create_stmt = extract_create_statement(statements)
              load_info = extract_load_info(create_stmt)
              strategy = select_deployment_strategy(statements)
              strategy.execute(client, statements, load_info)
            else
              statements.each do |stmt|
                logger.debug("Executing routine load command: #{stmt}") if logger.debug?
                client.run(stmt)
                log_command_execution(stmt)
              end
            end
          end
          logger.info("Deployed #{name}")
        end
      end
    end
  end
end 
