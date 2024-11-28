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
          with_connection do |client|
            resource.deploy(client)
          end
          logger.info("Resource deployed successfully")
        rescue Schematic::Starrocks::ConnectionError => e
          logger.error("Connection error: #{e.message}")
          raise
        rescue Schematic::Starrocks::StateTransformationError => e
          logger.error("State transformation error: #{e.message}")
          raise
        rescue Schematic::Starrocks::RoutineLoadError => e
          logger.error("Routine load error: #{e.message}")
          raise
        rescue StandardError => e
          logger.error("Unexpected error: #{e.message}")
          raise
        end

        def client
          @client ||= begin
            return options[:client] if options[:client]  # Keep this for testing

            connection_options = {
              adapter: options[:adapter],
              host: options[:host],
              port: options[:port],
              user: options[:user],
              password: options[:password],
              database: options[:database],
              read_timeout: 300,
              connect_timeout: 60,
              reconnect: true,
              pool_timeout: 30,
              max_connections: 5,
              loggers: [logger],
              log_sql: options[:log_sql],
              sql_log_level: options[:sql_log_level]
            }

            db = Sequel.connect(connection_options)
            db.extension :connection_validator
            db.pool.connection_validation_timeout = 30
            db
          end
        end

        def with_connection(&block)
          retries = 0
          max_retries = 3
          begin
            yield client
          rescue Sequel::DatabaseDisconnectError, Mysql2::Error::ConnectionError => e
            retries += 1
            if retries <= max_retries
              logger.warn("Connection lost, attempting to reconnect (#{retries}/#{max_retries})")
              sleep(2 * retries)
              @client&.disconnect rescue nil
              @client = nil
              retry
            else
              logger.error("Failed to reconnect after #{max_retries} attempts")
              raise
            end
          end
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
            port: ENV.fetch('DB_PORT', '9030').to_i,
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
          return if options[:skip_setup]  # Add this for testing if needed
          with_connection { |client| Database::StarRocks::Setup.ensure_migrations_table(client) }
        end

        def setup_connection(conn)
          conn
        end
      end
    end
  end
end
