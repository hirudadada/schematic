require 'pathname'

module Schematic
  class Vw

    def create(vwname)
      vw_template = <<~TEMPLATE
        CREATE VIEW [dbo].[#{vwname}]
        AS
          SELECT o.name AS object_name, o.object_id, o.type, o.type_desc, create_date, s.name AS schema_name, s.schema_id 
          FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id
          WHERE type = 'V' AND o.name = 'vw_name' AND s.name = 'dbo'

        TEMPLATE

      file_name = "#{vwname}.sql"
      FileUtils.mkdir_p(vw_dir)

      vw_file = File.join(vw_dir, file_name)

      File.open(vw_file, 'w') do |file|
        file.write(vw_template)
      end
      puts "New view template is created: #{vw_file}"
    end


    def deploy
      dir = Pathname.new(vw_dir)

      Dir.glob(dir.join('*.sql')) do |file|
        sql = File.read(file)

        # Split the SQL script into separate commands at each 'GO' statement
        commands = sql.split("\nGO")
        puts "\n  >> Executing script from #{file}\n"

        commands.each do |command|
          unless command.strip.empty?
            # Extract schema and view name from the command
            match_data = command.match(/CREATE\s+VIEW\s+\[(?<schema>.+)\]\.\[(?<view>.+)\]/i)
            next unless match_data

            schema_name = match_data[:schema]
            view_name = match_data[:view]

            db_name = @options[:db_name]
            # Check if the view exists
            check_sql = "SELECT * FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE type = 'V' AND o.name = '#{view_name}' AND s.name = '#{schema_name}'"
            result = db_connection.fetch(check_sql).all

            if result.nil? || result.empty?
              puts "  >> Create new view.\n\n"
              db_connection.run(command)
            else
              alter_command = command.gsub(/CREATE\s+VIEW/i, 'ALTER VIEW')
              puts "  >> Update existing view.\n\n"
              db_connection.run(alter_command)
            end


          end
        end
      end
    end
  end
end
