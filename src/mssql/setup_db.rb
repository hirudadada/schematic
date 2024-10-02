require 'yaml'
require 'sequel'

# Connect to the SQL Server
DB = Sequel.connect(adapter: 'tinytds', host: 'localhost', user: 'sa', password: ENV['MSSQL_SA_PASSWORD'])

File.open('databases.yaml') do |file|
  data = YAML.load(file)
  data['databases'].each do |db|
    # Switch to the database
    DB.run("USE #{db['DB_NAME']}")
    
    # Execute the SQL script
    File.read('setup-db.sql').split(';').each do |statement|
      DB.run(statement)
    end
  end
end