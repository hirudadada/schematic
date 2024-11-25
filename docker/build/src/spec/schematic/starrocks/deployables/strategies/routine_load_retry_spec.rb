require 'spec_helper'

RSpec.describe Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy do
  include_context "error handling routine load context"
  
  let(:strategy) { described_class.new(options) }
  let(:load_info) do
    {
      version: '1.0.0',
      db_name: 'test_db',
      routine_name: 'test_routine',
      operation: 'pause',
      table_name: 'test_table'
    }
  end

  describe '#execute_with_delay' do
    let(:mock_client) { double('client') }
    let(:logger) { Logger.new(nil) }
    let(:mock_dataset) do
      double('dataset').tap do |ds|
        allow(ds).to receive(:all).and_return([
          { 'State' => 'PAUSED' }
        ])
      end
    end

    before do
      allow(strategy).to receive(:logger).and_return(logger)
      allow(strategy).to receive(:load_info).and_return(load_info)
      allow(strategy).to receive(:sleep)
      allow(mock_client).to receive(:fetch).and_return(mock_dataset)
    end

    context 'with malformed packet error' do
      it 'retries the operation' do
        call_count = 0
        allow(mock_client).to receive(:run) do
          call_count += 1
          if call_count == 1
            raise StandardError, 'Received malformed packet'
          end
        end

        expect {
          strategy.send(:execute_with_delay, mock_client, 'PAUSE ROUTINE LOAD FOR `test_routine`')
        }.to raise_error(StandardError, /Received malformed packet/)
      end
    end

    context 'with state transformation errors' do
      before do
        allow(mock_client).to receive(:fetch).and_return(mock_dataset)
      end

      it 'handles already in desired state' do
        allow(mock_client).to receive(:run)
          .and_raise(StandardError, 'Could not transform PAUSED to PAUSED')

        expect {
          strategy.send(:execute_with_delay, mock_client, 'PAUSE ROUTINE LOAD FOR `test_routine`')
        }.not_to raise_error
      end
    end
  end
end