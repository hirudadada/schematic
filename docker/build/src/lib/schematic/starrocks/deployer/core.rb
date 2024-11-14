# frozen_string_literal: true

require 'sequel'
require 'logger'

module Schematic
  module Starrocks
    module Deployer
      class Core
        attr_reader :options

        def initialize(opts = {})
          @options = default_options.merge!(opts)
          yield @options if block_given?
          ensure_database_setup
        end

        def deploy_resource(resource)
          logger.info("Deploying resource...")
          resource.deploy(client)
          logger.info("Resource deployed successfully")
        rescue AnalyzingError => e
          logger.error("An unexpected error occurred: #{e.message}")
          raise
        end

        def client
          Sequel.connect(
            database_url,
            loggers: [init_logger],
            log_sql: options[:log_sql],
            sql_log_level: options[:sql_log_level],
            reconnect: true
          )
        end

        def work_dir
          @work_dir ||= init_work_dir
        end

        def resource_dir
          @resource_dir ||= init_resource_dir
        end

        def logger
          @logger ||= init_logger
        end

        private

        def init_work_dir
          options[:work_dir] || Dir.pwd
        end

        def init_resource_dir
          dir = Pathname.new(options[:resource_dir] || default_options[:resource_dir])
          dir.absolute? ? dir.to_s : File.join(work_dir, dir.to_s)
        end

        def init_logger
          logger = Logger.new($stdout)
          logger.level = options[:log_level]
          logger
        end

        def database_url
          "#{options[:adapter]}://#{options[:user]}:#{options[:password]}@#{options[:host]}:#{options[:port]}/#{options[:database]}"
        end

        def decrypt_password
          encrypted = ENV['DB_PASSWORD_ENCRYPTED']
          return ENV['DB_PASSWORD'] if encrypted.nil? || encrypted.empty?

          Schematic::Cipher.new.decrypt(encrypted)
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
            sql_log_level: :debug,
            log_level: Logger::INFO
          }
        end

        def ensure_database_setup
          Database::StarRocks::Setup.ensure_migrations_table(client)
        end
      end
    end
  end
end
