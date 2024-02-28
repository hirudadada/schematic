require 'pathname'
require 'json'

module Schematic
  class Seed

    def create(seedname)
      seed_template = <<~TEMPLATE
      {
        "UK": ["Source_System", "Source_DB","Source_Schema", "Source_Table", "Target_DB", "Target_Schema", "Target_Table"],
        "DW_ETL_LOG.ETL_Source_Configs": [
          {
            "TableID":"1",
            "Source_System":"ACSC",
            "Source_DB": "data-ingestion-acsc",
            "Source_Schema": "DW_ETL",
            "Source_Table": "SCL_G_CFPCN",
            "Target_DB": "data-ingestion-acsc",
            "Target_Schema": "DW_ETL",
            "Target_Table": "CASDD0PDV2_CFPCN",
            "Key_Mapping": "[ACCTCN], [ATYPCN]",
            "Batch_NoofRcds": "8000",
            "EntryType_to_ModLog": "NULL",
            "Max_Process_datetime": "2024-02-23 15:45:01",
            "Target_ModLog": "NULL",
            "Last_Modified": "NULL",
            "Remove_Journal": "Y",
            "Verification_exclude": "[CACTCN]",
            "Verification_Source_Rename": "NULL",
            "Target_Remove_Delete": "N",
            "Parsing_interval_ms": "15"
          }
        ]
      }
        TEMPLATE

      file_name = "#{seedname}.json"
      FileUtils.mkdir_p(seed_dir)

      seed_file = File.join(seed_dir, file_name)

      File.open(seed_file, 'w') do |file|
        file.write(seed_template)
      end
      puts "New seed data template is created: #{seed_file}"
    end

    def table_exist?(tbl_schema, tbl_name)
      information_schema = Sequel.qualify('INFORMATION_SCHEMA', 'TABLES')
      result = db_connection[information_schema]
          .where(TABLE_TYPE: 'BASE TABLE', TABLE_SCHEMA: tbl_schema, TABLE_NAME:tbl_name )
          .count
      return result > 0
    end

    def record_exist?(tbl_schema, tbl_name, record, uks)
      qualified_tbl_name = Sequel.qualify(tbl_schema, tbl_name)
      conditions = uks.map { |uk| { uk.to_sym => record[uk] } }
      result = db_connection[qualified_tbl_name].where(Sequel.&(*conditions)).count
      return result > 0
    end


    def deploy

      dir = Pathname.new(seed_dir)
      seed_files = Dir.glob(dir.join("*.json")).sort

      puts "\nStarting Seed data load processe... \n"
      ### Loading table by filename order
      seed_files.each do |f|
        puts "=================================================================\n"

            content = File.read(f)
            puts "Reading data from file #{f} ...\n\n"
            jcontent = JSON.parse(content)

            uks = jcontent["UK"]
            jcontent.delete("UK")

            jcontent.each do |tbl,row|
                tbl_schema, tbl_name = tbl.match(/(\w+).(\w+)/).captures
                qualified_tbl_name = Sequel.qualify(tbl_schema, tbl_name)

                # Check table exist?
                if table_exist?(tbl_schema, tbl_name)
                  puts "Loading data into Table: #{tbl} ...\n\n"

                  row.each do |r|
                    r.each do |k, v|
                      if v.is_a?(::Hash)
                        r[k] = v.to_json
                      end
                    end

                    # Check record exist by UK.
                    unless record_exist?(tbl_schema, tbl_name, r, uks)
                      db_connection[qualified_tbl_name].insert(r)
                    end
                  end
                  puts "Loading data into Table: #{tbl} ... DONE. \n\n"
                else 
                  puts "Table #{tbl} doesn't exist. quit...\n\n"
                end
            end


      end
      puts "Seed data load processes completed! \n"
    end
  end
end
