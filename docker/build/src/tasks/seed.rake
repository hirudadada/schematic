require_relative '../lib/schematic/seed'

namespace :seed do

  desc "Create a seed data template file "
  task :create, :name do |_, args|
    unless args.name
      abort 'Aborted! Seed file name is missing.'
      exit 1
    end

    Schematic::Seed.new.create(args.name)
  end

  desc "Load Seed data"
  task :deploy do |_, args|
    puts "\nStart Apply seed data to #{ENV['DB_NAME']} ...\n\n" unless Dir.glob("#{ENV['APP_HOME']}/db/seeds/*.json").empty?
    Schematic::Seed.new.deploy unless Dir.glob("#{ENV['APP_HOME']}/db/seeds/*.json").empty?
  end
end