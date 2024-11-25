module Schematic
  module Starrocks
    module Templates
      module Naming
        def self.generate_routine_name(table_name)
          "#{table_name}_rl"
        end

        def self.generate_migration_name(table_name, db_name, operation, timestamp = Time.now.strftime('%Y%m%d%H%M%S'))
          "#{timestamp}-#{operation}-#{db_name}-#{table_name}-rl"
        end

        def self.extract_info_from_filename(filename)
          # Example: "20241107092547-create-schematic-example_table-rl.sql"
          basename = File.basename(filename, '.*')
          parts = basename.split('-')

          raise StandardError, "Invalid filename format: #{filename}" unless parts.size >= 5

          timestamp, operation, db_name, table_name, *rest = parts

          raise StandardError, "Invalid filename format: missing routine-load suffix" unless rest.join('-') == 'rl'

          {
            timestamp: timestamp,
            operation: operation,
            db_name: db_name,
            table_name: table_name
          }
        end

        def self.generate_migration_version(timestamp = Time.now.strftime('%Y%m%d%H%M%S'))
          timestamp
        end
      end
    end
  end
end 
