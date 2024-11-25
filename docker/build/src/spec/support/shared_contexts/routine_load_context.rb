RSpec.shared_context "routine load context" do
  let(:provider) { TestProvider.new.prepare }
  
  let(:options) do
    {
      provider: provider,
      migration_mode: true,
      strategy: Schematic::Starrocks::Deployables::Strategies::RoutineLoadDeploymentStrategy.new,
      logger: logger,
      log_level: Logger::INFO
    }
  end

  let(:logger) do
    logger = Logger.new(nil)
    logger.level = Logger::INFO
    logger
  end

  let(:mock_client) { double('Sequel::Database') }
end
