# frozen_string_literal: true

module Schematic
  module Database
    module StarRocks
      class Setup < Database::Setup
        class << self
          def ensure_routine_load_migrations_table(client)
            return unless client&.run

            client.run(<<~SQL)
              CREATE TABLE IF NOT EXISTS routine_load_migrations (
                id BIGINT,
                version VARCHAR(14),
                name VARCHAR(255),
                table_name VARCHAR(255),
                routine_name VARCHAR(255),
                operation VARCHAR(50),
                applied_at DATETIME,
                PRIMARY KEY (id)
              )
              ENGINE=olap
              DISTRIBUTED BY HASH(id)
              PROPERTIES (
                "replication_num" = "1"
              );
            SQL
          end
        end
      end
    end
  end
end 
