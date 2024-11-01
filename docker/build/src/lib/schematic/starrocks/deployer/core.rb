# frozen_string_literal: true

require 'sequel'
require 'logger'

module Schematic
  module Starrocks
    class Deployer
      attr_reader :options

      def initialize(opts = {})
        @options = default_options.merge!(opts)
        yield @options if block_given?
      end

      def deploy_resource(resource)
        resource.deploy(client)
      rescue StandardError => e
        logger.error("An unexpected error occurred: #{e.message}")
        # logger.error(e.backtrace.join("\n"))
        raise e
      ensure
        if e&.message&.include?('MySQL server has gone away') ||
          e&.message&.include?('Getting analyzing error')
          reconnect
        end
      end

      def logger
        @logger ||= init_logger
      end

      def work_dir
        @work_dir ||= init_work_dir
      end

      def resource_dir
        @resource_dir ||= init_resource_dir
      end

      def client
        temp = init_client
        logger.debug "client object_id: #{@client.object_id}"
        @client ||= temp
      end

      private

      def init_client
        Sequel.connect(
          database_url,
          loggers: [init_logger],
          log_sql: false,
          sql_log_level: options[:sql_log_level] || :debug,
          reconnect: true
        )
      end

      def reconnect
        logger.info("Reconnecting to database...")
        @client.disconnect
        @client = init_client
        logger.debug "client object_id: #{@client.object_id}"
      end

      def default_options
        {
          host: ENV.fetch('DB_HOST', 'localhost'),
          port: ENV.fetch('DB_PORT', '9030'),
          database: ENV.fetch('DB_NAME', 'schematic'),
          user: ENV.fetch('DB_USER', 'root'),
          password: decrypt_password,
          adapter: ENV.fetch('DB_ADAPTER', 'mysql2'),
          work_dir: Dir.pwd,
          resource_dir: 'db/starrocks',
          log_sql: true,
          sql_log_level: :debug
        }
      end

      def init_logger
        logger = Logger.new($stdout)
        logger.level = options[:log_level] || Logger::DEBUG
        logger
      end

      # NOTE: skipped the original database_url, since the password resolution is done here
      def database_url
        "#{options[:adapter]}://#{options[:user]}:#{options[:password]}@#{options[:host]}:#{options[:port]}/#{options[:database]}"
      end

      def decrypt_password
        encrypted = ENV['DB_PASSWORD_ENCRYPTED']
        return ENV['DB_PASSWORD'] if encrypted.nil? || encrypted.empty?

        Schematic::Cipher.new.decrypt(encrypted)
      end

      def init_work_dir
        options[:work_dir] || default_options[:work_dir]
      end

      def init_resource_dir
        dir = Pathname.new(options[:resource_dir] || default_options[:resource_dir])
        dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
      end
    end
  end
end
