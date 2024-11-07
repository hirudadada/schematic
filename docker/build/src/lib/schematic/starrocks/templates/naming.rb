module Schematic
  module Starrocks
    module Templates
      module Naming
        def self.generate_routine_name(table_name)
          "rl_#{table_name}"
        end

        def self.generate_migration_name(table_name, operation, timestamp = Time.now.strftime('%Y%m%d%H%M%S'))
          "#{timestamp}_#{operation}_#{table_name}_routine_load"
        end

        def self.extract_info_from_filename(filename)
          # Example: "20241107092547_create_example_table_routine_load.sql"
          basename = File.basename(filename, '.*')
          timestamp, operation, table_name, *_ = basename.split('_')
          {
            timestamp: timestamp,
            operation: operation,
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