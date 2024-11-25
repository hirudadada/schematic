require 'spec_helper'
require 'schematic/starrocks'

RSpec.describe "StarRocks Error Scenarios" do
  include_context "error handling routine load context"

  let(:load_info) do
    {
      version: '1.0.0',
      db_name: 'test_db',
      routine_name: 'test_routine',
      operation: 'pause',
      table_name: 'test_table'
    }
  end

  let(:mock_dataset) do
    double('dataset').tap do |ds|
      allow(ds).to receive(:all).and_return([
        { 'State' => 'RUNNING' }
      ])
    end
  end

  before do
    allow(mock_client).to receive(:fetch).and_return(mock_dataset)
    allow(Schematic::Starrocks::Deployables::States::RoutineLoadState)
      .to receive(:get_state)
      .with(mock_client, load_info[:db_name], load_info[:routine_name])
      .and_return({ state: 'RUNNING', exists: true })
  end

  context "error handling scenarios" do
    it "handles database errors" do
      allow(mock_client).to receive(:run)
        .and_raise(StandardError, 'Database operation failed')

      expect {
        strategy.execute(mock_client, ['PAUSE ROUTINE LOAD FOR `test_routine`'], load_info)
      }.to raise_error(StandardError, /Database operation failed/)
    end

    it "handles state transformation errors" do
      # Mock the current state
      allow(Schematic::Starrocks::Deployables::States::RoutineLoadState)
        .to receive(:get_state)
        .with(mock_client, load_info[:db_name], load_info[:routine_name])
        .and_return({ state: 'PAUSED', exists: true })

      # Simulate a state transformation error
      allow(mock_client).to receive(:run)
        .and_raise(StandardError, 'Could not transform PAUSED to PAUSED')

      # Should not raise error when already in desired state
      expect {
        strategy.execute(mock_client, ['PAUSE ROUTINE LOAD FOR `test_routine`'], load_info)
      }.not_to raise_error
    end

    it "raises error for invalid state transformations" do
      # Mock the current state
      allow(Schematic::Starrocks::Deployables::States::RoutineLoadState)
        .to receive(:get_state)
        .with(mock_client, load_info[:db_name], load_info[:routine_name])
        .and_return({ state: 'RUNNING', exists: true })

      # Simulate an invalid state transformation
      allow(mock_client).to receive(:run)
        .and_raise(StandardError, 'Could not transform RUNNING to STOPPED')

      # Should raise error for invalid state transformation
      expect {
        strategy.execute(mock_client, ['STOP ROUTINE LOAD FOR `test_routine`'], load_info)
      }.to raise_error(StandardError)
    end
  end
end