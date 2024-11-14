# frozen_string_literal: true

module Schematic
  module Database
    module StarRocks
      class Setup < Database::Setup
        class << self
          # Called by Migrator during initialization
          def ensure_migrations_table(client)
            return unless client

            client.run(<<~SQL.strip)
              CREATE TABLE IF NOT EXISTS schema_migrations (
                filename VARCHAR(255) NOT NULL
              )
              ENGINE=olap
              PRIMARY KEY(filename)
              DISTRIBUTED BY HASH(filename);
            SQL
          end

          # Called on-demand by Routine Load features
          def ensure_routine_load_migrations_table(client)
            return unless client

            client.run(<<~SQL.strip)
              CREATE TABLE IF NOT EXISTS routine_load_migrations (
                id BIGINT,
                version VARCHAR(14),
                name VARCHAR(255),
                table_name VARCHAR(255),
                routine_name VARCHAR(255),
                operation VARCHAR(50),
                applied_at DATETIME
              )
              ENGINE=olap
              PRIMARY KEY(id)
              DISTRIBUTED BY HASH(id);
            SQL
          end
        end
      end
    end
  end
end 
