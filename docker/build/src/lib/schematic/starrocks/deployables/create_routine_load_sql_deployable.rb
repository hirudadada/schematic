# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class CreateRoutineLoadSqlDeployable < SqlDeployable
        def deploy(client)
          client.transaction do
            client.run(sql)
          end
          puts "Deployed #{name}"
        end
      end
    end
  end
end
