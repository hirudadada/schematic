require 'spec_helper'
require 'schematic/starrocks'
require 'schematic/starrocks/deployables/hydratable_deployable_resource'
require 'schematic/starrocks/deployables/hydratable_routine_load_sql_deployable'
require 'schematic/starrocks/deployables/hydratable_routine_load_config_deployable'

RSpec.describe "Routine Load Deployables Integration" do
  # Define operations
  OPERATIONS = [:create, :pause, :alter, :resume, :stop].freeze
  FORMATS = [:sql, :yaml].freeze

  let(:migration_info) do
    OPERATIONS.each_with_object({}) do |operation, hash|
      hash[operation] = {
        sql: get_migration_info(operation, 'sql'),
        yaml: get_migration_info(operation, 'yaml')
      }
    end
  end

  class TestProvider < Schematic::Starrocks::Providers::RoutineLoadConfigProvider
    def db_name
      'schematic'
    end

    def prepare
      self
    end
  end

  let(:logger) do
    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    logger
  end

  let(:provider) do
    TestProvider.new.prepare
  end

  let(:options) do
    {
      provider: provider,
      migration_mode: true,
      strategy: Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy.new,
      logger: logger,
      log_level: Logger::INFO
    }
  end

  describe "SQL Deployable" do
    context "CREATE operation" do
      let(:info) { migration_info[:create][:sql] }
      let(:sql_content) { File.read(info[:path]) }
      let(:deployable) { 
        Schematic::Starrocks::Deployables::HydratableRoutineLoadSqlDeployable.new(
          info[:filename],
          sql_content,
          options
        )
      }

      it "parses and validates CREATE operation" do
        statements = deployable.parse_statements(sql_content)
        expect(statements.size).to eq(1)
        
        load_info = deployable.extract_load_info(statements.first)
        expect(load_info).to include(
          db_name: info[:db_name],
          routine_name: info[:routine_name],
          operation: info[:operation],
          table_name: info[:table_name]
        )
      end

      it "validates SQL patterns" do
        statements = deployable.parse_statements(sql_content)
        create_stmt = deployable.extract_create_statement(statements)
        
        expect { deployable.validate_create_statement!(create_stmt) }.not_to raise_error
      end
    end

    context "ALTER operation" do
      let(:info) { migration_info[:alter][:sql] }
      let(:sql_content) { File.read(info[:path]) }
      let(:deployable) { 
        Schematic::Starrocks::Deployables::HydratableRoutineLoadSqlDeployable.new(
          info[:filename],
          sql_content,
          options
        )
      }

      it "extracts correct load info" do
        statements = deployable.parse_statements(sql_content)
        load_info = deployable.extract_load_info(statements.first)
        expect(load_info).to include(
          db_name: info[:db_name],
          routine_name: info[:routine_name],
          operation: info[:operation],
          table_name: info[:table_name]
        )
      end

      it "validates SQL patterns" do
        statements = deployable.parse_statements(sql_content)
        expect { deployable.validate_statements!(statements) }.not_to raise_error
      end
    end

    context "state change operations" do
      [:pause, :resume, :stop].each do |operation|
        context "#{operation} operation" do
          let(:info) { migration_info[operation][:sql] }
          let(:sql_content) { File.read(info[:path]) }
          let(:deployable) {
            Schematic::Starrocks::Deployables::HydratableRoutineLoadSqlDeployable.new(
              info[:filename],
              sql_content,
              options
            )
          }

          it "extracts correct load info" do
            statements = deployable.parse_statements(sql_content)
            load_info = deployable.extract_load_info(statements.first)
            expect(load_info).to include(
              db_name: info[:db_name],
              routine_name: info[:routine_name],
              operation: info[:operation],
              table_name: info[:table_name]
            )
          end
        end
      end
    end
  end

  describe "Config Deployable" do
    context "CREATE operation" do
      let(:info) { migration_info[:create][:yaml] }
      let(:yaml_content) { YAML.load_file(info[:path]) }
      let(:deployable) {
        Schematic::Starrocks::Deployables::HydratableRoutineLoadConfigDeployable.new(
          info[:filename],
          yaml_content,
          options
        )
      }

      it "validates CREATE operation config" do
        load_info = deployable.extract_load_info(yaml_content)
        expect(load_info).to include(
          db_name: info[:db_name],
          routine_name: info[:routine_name],
          operation: info[:operation],
          table_name: info[:table_name]
        )
      end
    end

    context "ALTER operation" do
      let(:info) { migration_info[:alter][:yaml] }
      let(:yaml_content) { YAML.load_file(info[:path]) }
      let(:deployable) {
        Schematic::Starrocks::Deployables::HydratableRoutineLoadConfigDeployable.new(
          info[:filename],
          yaml_content,
          options
        )
      }

      it "validates ALTER operation config" do
        load_info = deployable.extract_load_info(yaml_content)
        expect(load_info).to include(
          db_name: info[:db_name],
          routine_name: info[:routine_name],
          operation: info[:operation],
          table_name: info[:table_name]
        )
      end

      it "contains only alterable properties" do
        expect(yaml_content[:properties].keys).to include(
          :desired_concurrent_number,
          :max_error_number,
          :max_batch_interval,
          :max_batch_rows,
          :max_batch_size,
          :jsonpaths
        )
      end
    end

    context "state change operations" do
      [:pause, :resume, :stop].each do |operation|
        context "#{operation} operation" do
          let(:info) { migration_info[operation][:yaml] }
          let(:yaml_content) { YAML.load_file(info[:path]) }
          let(:deployable) {
            Schematic::Starrocks::Deployables::HydratableRoutineLoadConfigDeployable.new(
              info[:filename],
              yaml_content,
              options
            )
          }

          it "extracts correct load info" do
            load_info = deployable.extract_load_info(yaml_content)
            expect(load_info).to include(
              db_name: info[:db_name],
              routine_name: info[:routine_name],
              operation: info[:operation],
              table_name: info[:table_name]
            )
          end
        end
      end
    end
  end
end