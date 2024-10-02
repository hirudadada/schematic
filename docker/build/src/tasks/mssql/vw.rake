require_relative '../lib/schematic/vw'

namespace :vw do
  desc "Create a vies template file "
  task :create, :name do |_, args|
    unless args.name
      abort 'Aborted! View name is missing.'
      exit 1
    end

    Schematic::Vw.new.create(args.name)
  end

  desc "Apply views"
  task :deploy do |_, args|
    puts "\nStart Apply views to #{ENV['DB_NAME']} ...\n" unless Dir.glob("#{ENV['APP_HOME']}/views/*.sql").empty?
    Schematic::Vw.new.deploy unless Dir.glob("#{ENV['APP_HOME']}/views/*.sql").empty?
  end
end