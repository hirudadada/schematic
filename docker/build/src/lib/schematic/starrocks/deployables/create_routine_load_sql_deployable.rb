# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateRoutineLoadSqlDeployable < SqlDeployable
        def deploy(client)
          client.run("DROP ROUTINE LOAD IF EXISTS #{name}")
          client.run(sql)
          puts "Deployed #{name}"
        rescue Mysql2::Error => e
          puts "Error deploying #{name}: #{e.message}"
        end
      end
    end
  end
end
