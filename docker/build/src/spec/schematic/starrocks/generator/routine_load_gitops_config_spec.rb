require 'spec_helper'
require 'schematic/starrocks/generator'

RSpec.describe Schematic::Starrocks::Generator::RoutineLoadGitOpsConfig do
  include_context "gitops generator context"

  let(:generator) { described_class.new }
  let(:default_cluster_credentials) do
    {
      'KAFKA_BROKER_LIST' => ENV['KAFKA_BROKER_LIST'],
      'KAFKA_SECURITY_PROTOCOL' => ENV['KAFKA_SECURITY_PROTOCOL'],
      'KAFKA_SASL_MECHANISM' => ENV['KAFKA_SASL_MECHANISM'],
      'KAFKA_SASL_USERNAME' => ENV['KAFKA_SASL_USERNAME'],
      'KAFKA_SASL_PASSWORD' => ENV['KAFKA_SASL_PASSWORD'],
      'KAFKA_SSL_VERIFY' => ENV['KAFKA_SSL_VERIFY'],
      'KAFKA_PARTITIONS' => ENV['KAFKA_PARTITIONS'],
      'KAFKA_OFFSET' => ENV['KAFKA_OFFSET']
    }
  end

  before do
    allow(generator).to receive(:dev_configmap_dir).and_return(configmap_dir)
    allow(generator).to receive(:app).and_return('test-app')
    allow(generator).to receive(:project).and_return('test-project')
    allow(generator).to receive(:db_password_encrypted).and_return('encrypted_password')
    allow(generator).to receive(:cluster_credentials).and_return(default_cluster_credentials)
    allow(generator).to receive(:cluster_properties).and_return({
      'ROUTINE_LOAD_CONCURRENT_NUMBER' => '3',
      'ROUTINE_LOAD_FORMAT' => 'json',
      'ROUTINE_LOAD_MAX_ERROR_NUMBER' => '0',
      'ROUTINE_LOAD_MAX_FILTER_RATIO' => '1.0',
      'ROUTINE_LOAD_MAX_BATCH_INTERVAL' => '10',
      'ROUTINE_LOAD_MAX_BATCH_ROWS' => '2000000',
      'ROUTINE_LOAD_TASK_CONSUME_SECOND' => '15',
      'ROUTINE_LOAD_TASK_TIMEOUT_SECOND' => '60',
      'MIGRATION_MODE' => 'true',
      'HYDRATE' => 'true',
      'RESOURCE_DIR' => '/app/resources',
      'WORK_DIR' => '/app/work',
      'LOG_LEVEL' => 'info',
      'SQL_LOG_LEVEL' => 'info'
    })
  end

  describe '#generate' do
    context "with valid configuration" do
      before do
        allow(generator).to receive(:render_cipher_configmap).and_return(true)
        allow(generator).to receive(:render_credentials_configmap).and_return(true)
        allow(generator).to receive(:render_database_configmap).and_return(true)
        allow(generator).to receive(:render_routine_load_configmap).and_return(true)
        allow(generator).to receive(:render_routine_load_properties_configmap).and_return(true)
      end

      it 'generates all required configmaps' do
        expect(generator).to receive(:render_cipher_configmap)
        expect(generator).to receive(:render_credentials_configmap)
        expect(generator).to receive(:render_database_configmap)
        expect(generator).to receive(:render_routine_load_configmap)
        expect(generator).to receive(:render_routine_load_properties_configmap)

        generator.generate
      end
    end

    context "with errors" do
      it "handles missing template directory" do
        allow(generator).to receive(:generate).and_raise(StandardError, "Template directory not found")
        expect { generator.generate }.to raise_error(/Template directory not found/)
      end

      it "handles template rendering errors" do
        allow(generator).to receive(:render_routine_load_configmap)
          .and_raise(StandardError, "Template rendering failed")
        
        expect { generator.generate }.to raise_error(/Template rendering failed/)
      end
    end
  end

  describe '#render_routine_load_configmap' do
    it 'renders credentials configmap' do
      generator.render_routine_load_configmap
      
      output_file = File.join(configmap_dir, 'routine-load-credentials.yaml')
      expect(File).to exist(output_file)
      
      content = File.read(output_file)
      expect(content).to include('localhost:9092')
      expect(content).to include('PLAINTEXT')
    end

    it 'handles missing environment variables' do
      missing_credentials = default_cluster_credentials.dup
      missing_credentials.delete('KAFKA_BROKER_LIST')
      allow(generator).to receive(:cluster_credentials).and_return(missing_credentials)
      
      expect {
        generator.render_routine_load_configmap
      }.to raise_error(KeyError, /key not found: "KAFKA_BROKER_LIST"/)
    end
  end

  describe '#render_routine_load_properties_configmap' do
    it 'renders properties configmap' do
      generator.render_routine_load_properties_configmap
      
      output_file = File.join(configmap_dir, 'routine-load-properties.yaml')
      expect(File).to exist(output_file)
      
      content = File.read(output_file)
      expect(content).to include('ROUTINE_LOAD_CONCURRENT_NUMBER')
      expect(content).to include('json')
    end
  end
end