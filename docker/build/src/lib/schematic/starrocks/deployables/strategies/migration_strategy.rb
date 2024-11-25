# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class MigrationStrategy < RoutineLoadDeploymentStrategy
          def execute(client, statements, load_info)
            # Ensure migrations table exists if we're using migration strategy
            Database::StarRocks::Setup.ensure_routine_load_migrations_table(client)

            # Extract migration info from filename
            info = Templates::Naming.extract_info_from_filename(@name)
            table_name = load_info[:table_name] || info[:table]
            routine_name = load_info[:routine_name]
            operation = load_info[:operation].to_s

            # Skip if already applied
            if States::MigrationTracker.migration_applied?(client, @name, operation)
              logger.info("Migration #{info[:timestamp]} #{table_name}:#{routine_name} operation #{operation} already applied, skipping...")
              return
            end

            super

            # Record the migration with all fields
            States::MigrationTracker.record_migration(
              client,
              version: info[:timestamp],
              name: @name,
              table_name: table_name,
              routine_name: routine_name,
              operation: operation
            )

            logger.info("Migration #{info[:timestamp]} operation #{operation} applied successfully")
          end
        end
      end
    end
  end
end 
