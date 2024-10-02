# frozen-string-literal: true

require_relative '../../lib/schematic/migrator'

namespace :db do
  desc "Test database connection"
  task :test do |_, args|
    migrator = Schematic::Migrator.new
    if migrator.db_connection_test
      puts "Succeeded to connect to database: #{migrator.options[:db_host]}/#{migrator.options[:db_name]}"
    else
      puts "Failed to connect to database: #{migrator.options[:db_host]}/#{migrator.options[:db_name]}"
    end
  end

  desc "Run migrations"
  task :migrate, :version, :app do |_, args|
    puts "\nStart schema migration to #{ENV['DB_NAME']} ...\n" unless Dir.glob("#{ENV['APP_HOME']}/db/migrations/*.rb").empty?
    version = args[:version].to_i if args[:version]
    Schematic::Migrator.new.migrate(version: version, app: args.app) unless Dir.glob("#{ENV['APP_HOME']}/db/migrations/*.rb").empty?
  end

  desc "Remove migrations"
  task :clean, :app do |_, args|
    Schematic::Migrator.new.clean(app: args.app)
  end

  desc "Remove migrations and re-run migrations"
  task :reset, :app do |_, args|
    Schematic::Migrator.new.reset(app: args.app)
  end

  desc "Apply last n migrations"
  task :apply, :steps, :app do |_, args|
    Schematic::Migrator.new.apply(steps: args.steps || 1, app: args.app)
  end

  desc "Rollback last n migrations"
  task :rollback, :steps, :app do |_, args|
    Schematic::Migrator.new.rollback(steps: args.steps || 1, app: args.app)
  end

  desc "Redo last n migrations"
  task :redo, :steps, :app do |_, args|
    Schematic::Migrator.new.redo(steps: args.steps || 1, app: args.app)
  end


  desc "Create a migration file with a timestamp and name"
  task :create_migration, :name do |_, args|
    unless args.name
      abort 'Aborted! Migration name is missing.'
      exit 1
    end

    Schematic::Migrator.new.create_migration(args.name)
  end

  desc "Show applied schema migrations"
  task :applied_migrations, :app do |_, args|
    app = args.app
    Schematic::Migrator.new.show_applied_migrations(app)
  end

  desc "Show a given applied schema migration"
  task :applied_migration, :steps, :app do |_, args|
    steps = (args.steps || -1).to_i
    app = args.app
    Schematic::Migrator.new.show_applied_migration(steps,app)
  end

  desc "Show schema migrations to apply"
  task :migrations_to_apply, :app do |_, args|
    app = args.app
    Schematic::Migrator.new.show_migrations_to_apply(app)
  end

  desc "Show a given schema migration to apply"
  task :migration_to_apply, :steps, :app do |_, args|
    steps = (args.steps || 0).to_i
    app = args.app
    Schematic::Migrator.new.show_migration_to_apply(steps,app)
  end
end
