# frozen_string_literal: true

module Schematic
  module Starrocks
    class DeploymentError < StandardError; end

    class Deployer
      attr_reader :options

      def initialize(opts = {})
        @options = default_options.merge(opts)
        yield options if block_given?
        set_database_options
      end

      def work_dir
        @work_dir ||= options[:work_dir]
      end

      def resource_dir
        @resource_dir ||= init_resource_dir
      end

      def deploy_resource(resource)
        begin
          resource.deploy(db_connection)
        rescue Sequel::Error, Mysql2::Error => e
          error_message = handle_error(e, resource.name)
          log_error(error_message)
          log_stack_trace(e)
        rescue Errno::ENOENT => e
          error_message = "File not found: #{e.message}"
          log_error(error_message)
          log_stack_trace(e)
        rescue StandardError => e
          error_message = "An unexpected error occurred: #{e.message}"
          log_error(error_message)
          log_stack_trace(e)
        end
      end

      protected

      def handle_error(e, resource_name)
        "Sequel Error deploying #{resource_name}: #{e.message}"
        if e.message.include?("Commands out of sync")
          handle_commands_out_of_sync_error(e)
        else
          "An error occurred: #{e.message}"
        end
      end

      def handle_commands_out_of_sync_error(e)
        # Disconnect the existing connection
        @db_connection.disconnect if @db_connection

        # Establish a new connection
        @db_connection = db_connection
      end

      def log_error(error_message)
        puts error_message
      end

      def log_stack_trace(e)
        puts "Stack trace:"
        puts e.backtrace.join("\n")
      end

      def default_options
        {
          work_dir: Dir.pwd,
          resource_dir: File.join('db', 'starrocks'),
          template_dir: File.join('templates', 'starrocks')
        }
      end

      def init_resource_dir
        dir = Pathname.new(options[:resource_dir])
        dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
      end

      def set_database_options
        @options[:db_type] = ENV['DB_TYPE']
        @options[:db_adapter] = ENV['DB_ADAPTER']
        @options[:db_host] = ENV['DB_HOST']
        @options[:db_name] = ENV['DB_NAME']
        @options[:db_user] = ENV['DB_USER']
        @options[:db_password] = decrypt_db_password
        @options[:database_url] = ENV['DATABASE_URL']
      end

      def decrypt_db_password
        encrypted_password = ENV['DB_PASSWORD_ENCRYPTED']
        return ENV['DB_PASSWORD'] if encrypted_password.nil? || encrypted_password.empty?

        Schematic::Cipher.new.decrypt(encrypted_password)
      end

      def db_connection
        @db_connection ||= Sequel.connect(
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
end
