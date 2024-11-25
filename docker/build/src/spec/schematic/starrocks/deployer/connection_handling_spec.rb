require 'spec_helper'

RSpec.describe Schematic::Starrocks::Deployer::Core do
  include_context "routine load context"
  
  let(:mock_pool) do
    double('pool').tap do |pool|
      allow(pool).to receive(:connection_validation_timeout=).and_return(pool)
      allow(pool).to receive(:connection_validation_timeout).and_return(30)
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
      allow(db).to receive(:extension).and_return(db)
      allow(db).to receive(:pool).and_return(mock_pool)
      allow(db).to receive(:run)
      allow(db).to receive(:disconnect)
      allow(db).to receive(:fetch).with(/SHOW ROUTINE LOAD/).and_return(mock_dataset)
      allow(db).to receive(:fetch).and_return(mock_dataset)
      allow(db).to receive(:transaction).and_yield
    end
  end

  let(:test_logger) do
    Logger.new(StringIO.new).tap do |logger|
      logger.level = Logger::INFO
      allow(logger).to receive(:warn).and_call_original
      allow(logger).to receive(:error).and_call_original
    end
  end

  let(:options) do
    {
      provider: provider,
      migration_mode: true,
      strategy: Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy.new,
      logger: test_logger,
      log_level: Logger::INFO,
      client: mock_db,
      skip_setup: true
    }
  end

  let(:core) { described_class.new(options) }

  shared_context "database setup mocks" do
    before do
      allow(Schematic::Database::StarRocks::Setup)
        .to receive(:ensure_migrations_table)
        .with(mock_db)
        .and_return(true)

      allow(Schematic::Database::StarRocks::Setup)
        .to receive(:ensure_routine_load_migrations_table)
        .with(mock_db)
        .and_return(true)

      allow(Schematic::Starrocks::Deployables::States::RoutineLoadState)
        .to receive(:get_state)
        .with(mock_db, anything, anything)
        .and_return({ state: 'RUNNING', exists: true })
    end
  end

  describe '#with_connection' do
    include_context "database setup mocks"

    before do
      allow(core).to receive(:sleep)  # Speed up tests
      allow(Sequel).to receive(:connect).and_return(mock_db)
    end

    context 'when connection succeeds' do
      it 'yields the client' do
        expect { |b| core.with_connection(&b) }.to yield_with_args(mock_db)
      end

      it 'executes database operations successfully' do
        expect(mock_db).to receive(:run).with(/SELECT 1/).and_return(true)
        core.with_connection { |c| c.run('SELECT 1') }
      end
    end

    context 'when connection fails permanently' do
      it 'raises error after max retries' do
        call_count = 0
        
        # Mock client to always fail
        allow(core).to receive(:client) do
          call_count += 1
          raise Mysql2::Error::ConnectionError.new("Lost connection")
        end

        # Execute and verify
        expect { core.with_connection { |c| c.run('SELECT 1') } }
          .to raise_error(Mysql2::Error::ConnectionError)
        expect(call_count).to be >= 3  # Should try max_retries times
      end
    end
  end
end