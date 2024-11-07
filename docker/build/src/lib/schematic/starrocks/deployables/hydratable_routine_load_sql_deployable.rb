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
                         extract_load_info(extract_create_statement(statements))
                       else
                         extract_load_info(statements.first)
                       end

            if @strategy
              @strategy.execute(client, statements, load_info)
            elsif has_create_statement?(statements)
              deployment_strategy = select_deployment_strategy(statements)
              deployment_strategy.execute(client, statements, load_info)
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
