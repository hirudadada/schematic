# frozen-string-literal: true

require "pathname"
require_relative "../cipher"

module Schematic
  class Migrator
    attr_reader :options
    attr_reader :default_options

    def initialize(opts = {})
      @options = opts
      yield @options if block_given?
      on_init
      set_default_options
      set_default_values
    end

    def default_migration_dir
      File.join("db", "migrations")
    end

    def default_migration_table = nil

    def migration_dir
      @migration_dir ||= init_migration_dir
    end

    def migration_table
      @migration_table ||= init_migration_table
    end

    def work_dir
      @work_dir ||= init_work_dir
    end

    def default_work_dir = Dir.pwd

    def db_connection_test = !db_connection.nil?

    protected

    def set_default_options
      @default_options ||= {
        work: default_work_dir,
        migration_dir: default_migration_dir,
        migration_table: default_migration_table
      }
    end

    def set_default_values
      @options = default_options.merge(@options)
    end

    def init_migration_dir
      dir = Pathname.new(options[:migration_dir] || default_migration_dir)
      dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
    end

    def init_migration_table
      (options[:migration_table] || default_migration_table)
    end

    def init_work_dir
      (options[:work_dir] || default_work_dir)
    end

    def on_init
      @options[:db_type] = ENV['DB_TYPE']
      @options[:db_adapter] = ENV['DB_ADAPTER']
      @options[:db_host] = ENV['DB_HOST']
      @options[:db_name] = ENV['DB_NAME']
      @options[:db_user] = ENV['DB_USER']
      @options[:db_password] = 
        ENV['DB_PASSWORD_ENCRYPTED'].nil? ||
        ENV['DB_PASSWORD_ENCRYPTED'].empty? ?
          ENV['DB_PASSWORD'] : 
          decrypt_db_password(ENV['DB_PASSWORD_ENCRYPTED'])
      @options[:database_url] = ENV['DATABASE_URL']
    end

    def decrypt_db_password(encrypted_password)
      Schematic::Cipher.new.decrypt(encrypted_password)
    end

    def db_connection
      @options[:db_connection] ||= 
        Sequel.connect(
          options[:database_url], 
          user: options[:db_user], 
          password: options[:db_password]
        ).tap do |db|
          if options[:db_type] == 'mssql'
            db.extension :identifier_mangling
            db.identifier_input_method = nil
            db.identifier_output_method = nil
            db.run "SET ANSI_NULLS ON"
          end
        end
    end
  end
end
