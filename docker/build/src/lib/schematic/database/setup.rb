# frozen_string_literal: true

module Schematic
  module Database
    class Setup
      class << self
        def ensure_database(client)
          return unless client&.database_type

          case client.database_type.to_s
          when 'mssql'
            ensure_mssql_database(client)
          when 'mysql'  # For StarRocks
            ensure_starrocks_database(client)
          end
        end

        def ensure_migrations_table(client)
          return unless client&.database_type
          case client.database_type.to_s
          when 'mssql'
            ensure_mssql_migrations_table(client)
          when 'mysql'  # For StarRocks
            ensure_starrocks_migrations_table(client)
          end
        end

        private

        def ensure_mssql_database(client)
          client.run(<<~SQL)
            IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '#{client.database}')
            BEGIN
              CREATE DATABASE [#{client.database}]
            END
          SQL
        end

        def ensure_starrocks_database(client)
          client.run(<<~SQL)
            CREATE DATABASE IF NOT EXISTS `#{client.database}`;
          SQL
        end

        def ensure_mssql_migrations_table(client)
          client.run(<<~SQL)
            IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[schema_migrations]') AND type in (N'U'))
            BEGIN
              CREATE TABLE [dbo].[schema_migrations] (
                [filename] NVARCHAR(255) NOT NULL PRIMARY KEY,
              )
            END
          SQL
        end

        def ensure_starrocks_migrations_table(client)
          client.run(<<~SQL)
            CREATE TABLE IF NOT EXISTS schema_migrations (
              filename VARCHAR(255) NOT NULL
            )
            ENGINE=olap
            PRIMARY KEY(filename)
            DISTRIBUTED BY HASH(filename);
          SQL
        end
      end
    end
  end
end 
