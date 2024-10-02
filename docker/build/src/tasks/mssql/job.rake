require_relative '../lib/schematic/job'

namespace :job do
  desc "Create job template files "
  task :create, :name do |_, args|
    unless args.name
      abort 'Aborted! job name is missing.'
      exit 1
    end

    Schematic::Job.new.create(args.name)
  end

  desc "Apply jobs"
  task :deploy do |_, args|
    puts "\nStart Apply jobs to #{ENV['DB_NAME']} ...\n\n" unless Dir.glob("#{ENV['APP_HOME']}/jobs/*.yaml").empty?
    require "dotenv"
    Dotenv.load(*Dir["#{ENV['ENV_HOME']}/**/*.env"])
    Schematic::Job.new.deploy unless Dir.glob("#{ENV['APP_HOME']}/jobs/*.yaml").empty?
  end
end
