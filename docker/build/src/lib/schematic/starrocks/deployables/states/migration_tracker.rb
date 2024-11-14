# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module States
        class MigrationTracker
          MIGRATIONS_TABLE = 'routine_load_migrations'

          def self.ensure_migrations_table(client)
            client.run(<<~SQL)
              CREATE TABLE IF NOT EXISTS #{MIGRATIONS_TABLE} (
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

          def self.record_migration(client, version:, name:, table_name:, routine_name:, operation:)
            # Get next id
            result = client.fetch(<<~SQL).first
              SELECT COALESCE(MAX(id), 0) + 1 as next_id FROM #{MIGRATIONS_TABLE};
            SQL
            next_id = result[:next_id]

            client.run(<<~SQL)
              INSERT INTO #{MIGRATIONS_TABLE} (
                id, version, name, table_name, routine_name, operation, applied_at
              ) VALUES (
                #{next_id}, '#{version}', '#{name}', '#{table_name}', '#{routine_name}',
                '#{operation}', NOW()
              );
            SQL
          end

          def self.migration_applied?(client, version, operation)
            result = client.fetch(<<~SQL).first
              SELECT 1 FROM #{MIGRATIONS_TABLE}
              WHERE version = '#{version}' AND operation = '#{operation}';
            SQL
            !result.nil?
          end

          def self.get_migrations(client)
            client.fetch(<<~SQL).all
              SELECT version, name, table_name, routine_name, operation, applied_at
              FROM #{MIGRATIONS_TABLE}
              ORDER BY version ASC;
            SQL
          end
        end
      end
    end
  end
end
