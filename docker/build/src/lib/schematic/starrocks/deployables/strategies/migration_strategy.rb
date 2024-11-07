# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      module Strategies
        class MigrationStrategy < RoutineLoadDeploymentStrategy
          def execute(client, statements, load_info)
            # Ensure migrations table exists if we're using migration strategy
            States::MigrationTracker.ensure_migrations_table(client)

            # Extract migration info from filename
            info = Templates::Naming.extract_info_from_filename(@name)
            table_name = load_info[:table_name] || info[:table]
            routine_name = load_info[:routine_name]
            operation = load_info[:operation].to_s

            # Skip if already applied
            if States::MigrationTracker.migration_applied?(client, info[:timestamp], operation)
              logger.info("Migration #{info[:timestamp]} operation #{operation} already applied, skipping...")
              return
            end

            # Execute the statements
            statements.each do |stmt|
              execute_with_delay(client, stmt)
            end

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

          private

          def check_and_stop_existing(client, db_name, routine_name)
            result = client.fetch("SHOW ROUTINE LOAD FROM `#{db_name}` WHERE NAME = '#{routine_name}'").all

            if result.any?
              stop_sql = "STOP ROUTINE LOAD FOR `#{routine_name}`"
              logger.debug("Stopping existing routine load: #{stop_sql}") if logger.debug?
              client.run(stop_sql)
              sleep(2)
            end
          end
        end
      end
    end
  end
end 
