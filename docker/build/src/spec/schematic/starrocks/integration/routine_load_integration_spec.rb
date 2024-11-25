require 'spec_helper'
require 'schematic/starrocks'

RSpec.describe Schematic::Starrocks::Deployer::Core, :integration do
  include_context "routine load context"

  # Add TestProvider class with all required configurations
  class TestProvider < Schematic::Starrocks::Providers::RoutineLoadConfigProvider
    def db_name
      'schematic'
    end

    def kafka_config
      {
        broker_list: 'localhost:9092',
        partitions: '0',
        offset: 'OFFSET_BEGINNING',
        security: {
          protocol: 'PLAINTEXT',
          mechanism: 'PLAIN',
          username: 'test_user',
          password: 'test_pass'
        },
        ssl_verify: false
      }
    end

    def schema_registry_config
      {
        url: 'http://localhost:8081',
        auth: {
          username: 'test_user',
          password: 'test_pass'
        }
      }
    end

    def prepare
      self
    end
  end

  let(:mock_dataset) do
    double('Sequel::Dataset').tap do |ds|
      allow(ds).to receive(:all).and_return([
        { 
          'Name' => 'example_table_rl',
          'State' => 'RUNNING',
          'Progress' => '100%'
        }
      ])
    end
  end

  let(:mock_db) do 
    double('Sequel::Database',
      database_type: 'mysql',
      database: 'schematic'
    ).tap do |db|
      # Add all necessary mock methods
      allow(db).to receive(:extension)
      allow(db).to receive(:pool).and_return(double('pool', connection_validation_timeout: 30))
      allow(db).to receive(:disconnect)
      allow(db).to receive(:run)
      
      # Mock routine load queries with proper dataset
      allow(db).to receive(:fetch).with(/SHOW ROUTINE LOAD/).and_return(mock_dataset)
      
      # Mock other fetch calls
      allow(db).to receive(:fetch).and_return(mock_dataset)
      
      # Add transaction support
      allow(db).to receive(:transaction).and_yield
    end
  end

  let(:options) do
    {
      provider: provider,
      migration_mode: true,
      strategy: Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy.new,
      logger: logger,
      log_level: Logger::INFO,
      client: mock_db
    }
  end

  let(:core) { described_class.new(options) }
  let(:migration_info) do
    {
      create: get_migration_info(:create, 'yaml'),
      pause: get_migration_info(:pause, 'yaml')
    }
  end

  context 'when deploying with connection issues' do
    # First create the routine load
    let(:create_deployable) do
      yaml_content = YAML.load_file(migration_info[:create][:path])
      Schematic::Starrocks::Deployables::HydratableRoutineLoadConfigDeployable.new(
        migration_info[:create][:filename],
        yaml_content,
        options
      )
    end

    # Then try to pause it with connection issues
    let(:pause_deployable) do
      yaml_content = YAML.load_file(migration_info[:pause][:path])
      Schematic::Starrocks::Deployables::HydratableRoutineLoadConfigDeployable.new(
        migration_info[:pause][:filename],
        yaml_content,
        options
      )
    end

    before do
      # Skip actual database setup
      allow(Schematic::Database::StarRocks::Setup)
        .to receive(:ensure_migrations_table)
        .with(mock_db)
        .and_return(true)

      allow(Schematic::Database::StarRocks::Setup)
        .to receive(:ensure_routine_load_migrations_table)
        .with(mock_db)
        .and_return(true)

      # Mock routine load state checks
      allow(Schematic::Starrocks::Deployables::States::RoutineLoadState)
        .to receive(:get_state)
        .with(mock_db, anything, anything)
        .and_return({ state: 'RUNNING', exists: true })

      # Deploy the create operation first
      core.deploy_resource(create_deployable)

      # Stub sleep to speed up tests
      allow_any_instance_of(Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy)
        .to receive(:sleep)
      allow(core).to receive(:sleep)
    end

    it 'handles temporary connection loss during state change' do
      call_count = 0
      
      # Mock database behavior
      allow(mock_db).to receive(:run) do |sql|
        call_count += 1
        if call_count == 2  # Let first run succeed (create), fail on second (pause), then succeed
          raise Mysql2::Error::ConnectionError, "Lost connection to MySQL server"
        end
        true
      end
    
      # Mock connection handling
      allow(Sequel).to receive(:connect).and_return(mock_db)
      allow(core).to receive(:sleep)  # Speed up retries
    
      # Execute and verify
      expect { core.deploy_resource(pause_deployable) }.not_to raise_error
      expect(call_count).to be > 2  # Should have: 1 successful + 1 failed + 1 retry successful
    end
  end
end