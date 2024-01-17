# frozen-string-literal: true

module Schematic
  class Migrator
    def show_applied_migrations(app)
        app = app.nil? ? nil : String(app)
        applied_migrations(app).each do |migration|
        version, file = migration.split('_', 2)
        puts "--> #{version} : #{File.basename(file, '.rb')}"
      end
    end

    def show_applied_migration(step,app)
      app = app.nil? ? nil : String(app)
      migration = applied_migration(step,app)

      if migration.empty?
        puts "Aborted! Migration step #{step} is not found; probably out of range"
      else
        puts "--> #{migration[:version]} : #{migration[:name]}"
      end
    end

    def show_migrations_to_apply(app)
      app = app.nil? ? nil : String(app)
      migrations_to_apply(app).each do |migration|
        version, file = migration.split('_', 2)
        puts "--> #{version} : #{File.basename(file, '.rb')}"
      end
    end

    def show_migration_to_apply(step,app)
      app = app.nil? ? nil : String(app)
      migration = migration_to_apply(step,app)
      if migration.empty?
        puts "Aborted! Migration step #{step} is not found; probably out of range"
      else
        puts "--> #{migration[:version]} : #{migration[:name]}"
      end
    end

    protected

    def applied_migrations(app)

      migration_table = "schema_migrations_#{app}" unless app.nil? 
      Sequel::Migrator.migrator_class(migration_dir).new(
        db_connection, 
        migration_dir,
        {table: migration_table}
      ).applied_migrations
    end

    def applied_migration(step,app)
      migration = applied_migrations(app)[step]
      if migration.nil?
        {}
      else
        version, file = migration.split('_', 2)
        { version: version.to_i, name: File.basename(file, '.rb') }
      end
    end

    def migrations_to_apply(app)
      migration_table = "schema_migrations_#{app}" unless app.nil? 
      migrator = Sequel::Migrator.migrator_class(migration_dir).new(
        db_connection, 
        migration_dir,
        {table: migration_table}
      )
      migrator.files.map do |file|
        File.basename(file)
      end - migrator.applied_migrations
    end

    def migration_to_apply(step,app)
      migration = migrations_to_apply(app)[step]
      if migration.nil?
        {}
      else
        version, file = migration.split('_', 2)
        { version: version.to_i, name: File.basename(file, '.rb') }
      end
    end
  end
end
