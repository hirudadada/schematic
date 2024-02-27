require "pathname"

module Schematic
  class Sqlsequel
    attr_reader :options
    attr_reader :default_options

    def initialize(opts = {})
      @options = opts
      yield @options if block_given?
      on_init
      set_default_options
      set_default_values
    end

    def work_dir
      @work_dir ||= init_work_dir
    end

    def default_work_dir = Dir.pwd

    def default_sql_dir = '.sqlsequel'

    def sql_dir
      @sql_dir ||= init_sql_dir
    end

    def sql_file = File.join(sql_dir, "a.sql")

    def create
      FileUtils.mkdir_p(File.dirname("#{sql_file}"))
      File.new(sql_file,"w")
      print "Empty file created. (#{sql_file})\n"
    end

    def conver
      require 'sequel'

        sql = File.read(sql_file)
        puts sql
        puts "-"*60 + "\n\n"
        File.open(sql_file, 'r') do |file|
          lines = file.readlines


          schema, table = lines.find { |line| line.include?('CREATE TABLE') }.match(/\[(\w+)\]\.\[(\w+)\]/).captures
          table_name = ":#{schema}, :#{table}"
          migration = "Sequel.migration do\n  change do\n    create_table(Sequel.qualify(#{table_name})) do\n"

          lines.select { |line| line.include?('[') && line.include?(']') && !line.include?('CREATE TABLE') }.each do |line|
            name_match = line.match(/\[(\w+)\]/)
            name = name_match[1] if name_match
            type_match = line.match(/\[(\w+)\]/, name_match.end(0)) if name_match
            type = type_match[1] if type_match
            ident_match = line.match(/IDENTITY\((\d+),(\d+)\)/) if ['int','bigint'].include?(type) && line.match(/IDENTITY\((\d+),(\d+)\)/)
            ident_match = " IDENTITY(#{ident_match[1].to_s}, #{ident_match[1].to_s}) " if ident_match
            sizing_match = line.match(/\((\d+)\)/) || line.match(/(max)/) if ['char','varchar','nvarchar'].include?(type) && (line.match(/\((\d+)\)/))|| line.match(/(max)/)
            sizing = sizing_match[1] if sizing_match
            precision_scale_match = line.match(/(\d+, \d+)/) if ['decimal','numeric'].include?(type) && line.match(/\((\d+, \d+)\)/)
            #precision, scale = precision_scale_match[1].to_i, precision_scale_match[2].to_i if precision_scale_match
            null = !line.include?('NOT NULL')
            #puts "#{line}                                                 >>> #{name} #{type} #{sizing} #{precision_scale_match} #{null} *  #{ident_match}"

            type = case type
                  when 'bigint' then ident_match ? "'bigint', auto_increment: true, primary_key: true" : "'bigint'"
                  when 'char' then "String, size: #{sizing}, fixed: true"
                  when 'varchar' then sizing == 'max' ? "String, size: :max" : "String, size: #{sizing}"
                  when 'nvarchar' then sizing == 'max' ? "'nvarchar', size: :max" : "'nvarchar', size: #{sizing}"
                  when 'int' then ident_match ? "Integer, auto_increment: true, primary_key: true" : 'Integer'
                  when 'decimal' then "'Decimal', size: [#{precision_scale_match.to_s}]"
                  when 'numeric' then "'Numeric', size: [#{precision_scale_match.to_s}]"
                  when 'datetime' then 'DateTime'
                  when 'datetime2' then "'DateTime2(7)'"
                  when 'text' then "String, text: true"
                  when 'date' then "Date"
                  when 'time' then "Time, only_time: true"
                  when 'bit','boolean' then "TrueClass"
                  when 'money' then "'money'"
                    
                  else raise "Unknown type: #{type}"
                  end
            migration += "      column :#{name}, #{type}, null: #{null}\n" if name && type

          end
          migration += "    end\n  end\nend\n"
          puts migration
        end
      end


    protected

    def set_default_options
      @default_options ||= {
      }
    end

    def set_default_values
      @options = default_options.merge(@options)
    end


    def init_sql_dir
      dir = Pathname.new(options[:sql_dir] || default_sql_dir)
      dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
    end

    def init_work_dir
      (options[:work_dir] || default_work_dir)
    end

    def on_init
    end

  end
end
