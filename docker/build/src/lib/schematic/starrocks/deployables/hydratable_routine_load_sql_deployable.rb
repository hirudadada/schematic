# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadSqlDeployable < StaticRoutineLoadSqlDeployable
        include Concerns::Hydratable

        def deploy(client)
          execute_with_hydration(client, data)
        end

        protected

        def execute_deploy(client, hydrated_data)
          client.transaction do
            statements = parse_statements(hydrated_data)
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
        end

        def hydrate_placeholders(data)
          Types::StrictString[data]
        end
      end
    end
  end
end 
