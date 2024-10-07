# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateMaterializedViewSqlDeployable < SqlDeployable
        def deploy(client)
          exists = client.run("SHOW MATERIALIZED VIEWS LIKE '#{name}'")
          client.run("DROP MATERIALIZED VIEW IF EXISTS #{name}") if exists
          create_stmt = "CREATE MATERIALIZED VIEW #{name} AS #{sql}"
          client.run(create_stmt)
        rescue Mysql2::Error => e
          puts "Error deploying #{name}: #{e.message}"
        end
      end
    end
  end
end

