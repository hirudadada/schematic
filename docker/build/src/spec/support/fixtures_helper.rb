module FixturesHelper
  def self.copy_migrations_to_fixtures
    source_dir = '/home/app/db/starrocks/routine_loads/migrations'
    target_dir = File.expand_path('../../fixtures/db/starrocks/routine_loads/migrations', __FILE__)
    
    FileUtils.mkdir_p(target_dir)
    FileUtils.cp_r(Dir["#{source_dir}/*"], target_dir)
  end

  def fixture_path(path)
    File.expand_path("../../fixtures/#{path}", __FILE__)
  end

  def self.fixture_path(path)
    File.expand_path("../../fixtures/#{path}", __FILE__)
  end

  def migrations_fixture_path
    File.expand_path('../../fixtures/db/starrocks/routine_loads/migrations', __FILE__)
  end

  def self.migrations_fixture_path
    File.expand_path('../../fixtures/db/starrocks/routine_loads/migrations', __FILE__)
  end

  def get_migration_info(operation, format)
    # Find all files of the given format
    files = Dir[File.join(migrations_fixture_path, "*.#{format}")]
    
    # Find the file matching the operation
    matching_file = files.find do |file|
      info = Schematic::Starrocks::Templates::Naming.extract_info_from_filename(file)
      info[:operation] == operation.to_s
    end

    return nil unless matching_file

    filename = File.basename(matching_file)
    info = Schematic::Starrocks::Templates::Naming.extract_info_from_filename(filename)

    {
      filename: filename,
      path: matching_file,
      table_name: info[:table_name],
      routine_name: "#{info[:table_name]}_rl",
      operation: info[:operation],
      timestamp: info[:timestamp],
      db_name: info[:db_name]
    }
  end
end 
