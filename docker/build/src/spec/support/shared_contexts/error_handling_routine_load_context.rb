RSpec.shared_context "error handling routine load context" do
  include_context "routine load context"

  let(:core) { Schematic::Starrocks::Deployer::Core.new(options) }
  let(:strategy) { options[:strategy] }
  
  let(:mock_client) do
    double('Sequel::Database').tap do |client|
      allow(client).to receive(:transaction).and_yield
      allow(client).to receive(:run)
      allow(client).to receive(:fetch).and_return([])
    end
  end

  let(:error_tracker) do
    Class.new do
      attr_reader :errors
      def initialize
        @errors = []
      end
      
      def track(error)
        @errors << error
      end
    end.new
  end

  before do
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error) do |msg|
      error_tracker.track(msg)
    end
  end
end
