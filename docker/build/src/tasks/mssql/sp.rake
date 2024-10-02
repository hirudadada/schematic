require_relative '../lib/schematic/sp'

namespace :sp do
  desc "Create a stored procedure template file "
  task :create, :name do |_, args|
    unless args.name
      abort 'Aborted! Stored procedure name is missing.'
      exit 1
    end

    Schematic::Sp.new.create(args.name)
  end

  desc "Apply stored procedures"
  task :deploy do |_, args|
    puts "\nStart Apply Stored Procedures to #{ENV['DB_NAME']} ...\n" unless Dir.glob("#{ENV['APP_HOME']}/stored_procedures/*.sql").empty?
    Schematic::Sp.new.deploy unless Dir.glob("#{ENV['APP_HOME']}/stored_procedures/*.sql").empty?
  end
end