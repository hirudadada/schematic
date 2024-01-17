# frozen-string-literal: true

module Schematic
  class Migrator
    def migrate(version: nil, app: nil)
      run_migrator(target: version.nil? ? nil : Integer(version),app: app.nil? ? nil : String(app))
      
      puts "Completed migration up of #{options[:db_name]}"
    end

    def clean(app: nil)
      run_migrator(target: 0, app: app)
      puts "Completed migration clean of #{options[:db_name]}"
    end

    def reset(app: nil)
      clean(app: app)
      migrate(version: nil, app: app)
      puts "Completed migration reset of #{options[:db_name]}"
    end

    def apply(steps: 1, app: nil)
      steps = Integer(steps)
      up(steps, app)
      puts "Completed migration up of #{options[:db_name]} for #{steps} step(s)"
    end

    def rollback(steps: 1, app: nil)
      steps = Integer(steps)
      app = app.nil? ? nil : String(app)
      down(steps, app)
      puts "Completed migration down of #{options[:db_name]} for #{steps} step(s)"
    end

    def redo(steps: 1, app: nil)
      steps = Integer(steps)
      app = app.nil? ? nil : String(app)
      down(steps, app)
      up(steps, app)
      puts "Completed migration redo of #{options[:db_name]} for #{steps} step(s)"
    end


    protected

    def up(steps, app)
      run_migrator(target: migration_to_apply(steps - 1, app)[:version], app: app)
    end

    def down(steps, app)
      run_migrator(target: applied_migration(- steps - 1, app)[:version] || 0, app: app)
    end

    def run_migrator(**opts)
      puts **opts
      migration_table = "schema_migrations_#{opts[:app]}" unless opts[:app].nil? 
      Sequel::Migrator.run(
        db_connection,
        migration_dir,
        table: migration_table, **opts
      )
    end

  end
end
