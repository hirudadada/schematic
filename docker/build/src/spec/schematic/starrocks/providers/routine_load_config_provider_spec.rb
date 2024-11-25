require 'spec_helper'
require 'schematic/starrocks/providers'

RSpec.describe Schematic::Starrocks::Providers::RoutineLoadConfigProvider do
  let(:provider) { described_class.new }
  let(:cipher) { instance_double(Schematic::Cipher) }

  before do
    allow(Schematic::Cipher).to receive(:new).and_return(cipher)
    allow(cipher).to receive(:decrypt).with('encrypted_kafka_pass').and_return('decrypted_kafka_pass')
    allow(cipher).to receive(:decrypt).with('encrypted_registry_pass').and_return('decrypted_registry_pass')

    # Load environment variables from make.env/starrocks/cluster.env
    ENV['KAFKA_BROKER_LIST'] = 'broker1:9092,broker2:9092'
    ENV['KAFKA_SECURITY_PROTOCOL'] = 'SASL_SSL'
    ENV['KAFKA_SASL_MECHANISM'] = 'PLAIN'
    ENV['KAFKA_SASL_USERNAME'] = 'kafka_user'
    ENV['KAFKA_SSL_VERIFY'] = 'false'
    ENV['KAFKA_PARTITIONS'] = '0,1,2'
    ENV['KAFKA_OFFSET'] = 'OFFSET_BEGINNING'
    ENV['SCHEMA_REGISTRY_URL'] = 'schema-registry:8081'
    ENV['SCHEMA_REGISTRY_USERNAME'] = 'registry_user'

    # Set default passwords to pass validation
    ENV['KAFKA_SASL_PASSWORD'] = 'kafka_password'
    ENV['SCHEMA_REGISTRY_PASSWORD'] = 'registry_password'
  end

  after do
    # Clean up environment variables
    %w[
      KAFKA_BROKER_LIST KAFKA_SECURITY_PROTOCOL KAFKA_SASL_MECHANISM
      KAFKA_SASL_USERNAME KAFKA_SASL_PASSWORD KAFKA_SASL_PASSWORD_ENCRYPTED
      KAFKA_SSL_VERIFY KAFKA_PARTITIONS KAFKA_OFFSET
      SCHEMA_REGISTRY_URL SCHEMA_REGISTRY_USERNAME
      SCHEMA_REGISTRY_PASSWORD SCHEMA_REGISTRY_PASSWORD_ENCRYPTED
    ].each { |key| ENV.delete(key) }
  end

  describe '#prepare' do
    it 'initializes with default values from env' do
      provider.prepare
      expect(provider.kafka_config[:broker_list]).to eq('broker1:9092,broker2:9092')
      expect(provider.kafka_config[:security][:protocol]).to eq('SASL_SSL')
      expect(provider.kafka_config[:security][:password]).to eq('kafka_password')
      expect(provider.schema_registry_config[:auth][:password]).to eq('registry_password')
    end

    context 'with password precedence' do
      it 'prefers encrypted password over plain password when both provided' do
        ENV['KAFKA_SASL_PASSWORD'] = 'kafka_password'
        ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'] = 'encrypted_kafka_pass'
        ENV['SCHEMA_REGISTRY_PASSWORD'] = 'registry_password'
        ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'] = 'encrypted_registry_pass'

        provider.prepare
        expect(provider.kafka_config[:security][:password]).to eq('decrypted_kafka_pass')
        expect(provider.schema_registry_config[:auth][:password]).to eq('decrypted_registry_pass')
      end

      it 'uses plain password when encrypted is not provided' do
        ENV['KAFKA_SASL_PASSWORD'] = 'kafka_password'
        ENV['SCHEMA_REGISTRY_PASSWORD'] = 'registry_password'
        ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'] = nil
        ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'] = nil

        provider.prepare
        expect(provider.kafka_config[:security][:password]).to eq('kafka_password')
        expect(provider.schema_registry_config[:auth][:password]).to eq('registry_password')
      end

      it 'uses encrypted password when plain is not provided' do
        ENV['KAFKA_SASL_PASSWORD'] = nil
        ENV['SCHEMA_REGISTRY_PASSWORD'] = nil
        ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'] = 'encrypted_kafka_pass'
        ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'] = 'encrypted_registry_pass'

        provider.prepare
        expect(provider.kafka_config[:security][:password]).to eq('decrypted_kafka_pass')
        expect(provider.schema_registry_config[:auth][:password]).to eq('decrypted_registry_pass')
      end
    end

    context 'with missing credentials' do
      before do
        ENV['KAFKA_SASL_PASSWORD'] = nil
        ENV['KAFKA_SASL_PASSWORD_ENCRYPTED'] = nil
        ENV['SCHEMA_REGISTRY_PASSWORD'] = nil
        ENV['SCHEMA_REGISTRY_PASSWORD_ENCRYPTED'] = nil
      end

      it 'raises error when both password types are missing for Kafka' do
        expect { provider.prepare }.to raise_error(
          ArgumentError,
          "Either KAFKA_SASL_PASSWORD or KAFKA_SASL_PASSWORD_ENCRYPTED must be provided"
        )
      end

      it 'raises error when both password types are missing for Schema Registry' do
        ENV['KAFKA_SASL_PASSWORD'] = 'kafka_password'
        
        expect { provider.prepare }.to raise_error(
          ArgumentError,
          "Either SCHEMA_REGISTRY_PASSWORD or SCHEMA_REGISTRY_PASSWORD_ENCRYPTED must be provided"
        )
      end
    end
  end

  describe '#properties' do
    before do
      allow(ENV).to receive(:[]).with('KAFKA_SASL_PASSWORD').and_return('kafka_password')
      allow(ENV).to receive(:[]).with('SCHEMA_REGISTRY_PASSWORD').and_return('registry_password')
      provider.prepare
    end

    context 'with create operation' do
      it 'returns all properties from cluster.env' do
        props = provider.properties(:create)
        expect(props.transform_keys(&:to_s)).to include(
          'desired_concurrent_number' => '3',
          'format' => 'json',
          'max_error_number' => '0',
          'max_filter_ratio' => '1.0',
          'max_batch_interval' => '10',
          'max_batch_rows' => '2000000',
          'task_consume_second' => '15',
          'task_timeout_second' => '60'
        )
      end
    end

    context 'with alter operation' do
      it 'returns only alterable properties' do
        props = provider.properties(:alter)
        string_keys = props.keys.map(&:to_s)
        expect(string_keys).to contain_exactly(
          'desired_concurrent_number',
          'max_error_number',
          'max_batch_interval',
          'max_batch_rows',
          'max_batch_size',
          'jsonpaths'
        )
      end
    end

    context 'with other operations' do
      it 'returns empty hash' do
        expect(provider.properties(:pause)).to be_empty
        expect(provider.properties(:resume)).to be_empty
        expect(provider.properties(:stop)).to be_empty
      end
    end
  end

  describe '#kafka_config' do
    it 'returns configured kafka settings' do
      provider.prepare
      config = provider.kafka_config
      expect(config).to include(
        broker_list: 'broker1:9092,broker2:9092',
        partitions: '0,1,2',
        offset: 'OFFSET_BEGINNING'
      )
      expect(config[:security]).to include(
        protocol: 'SASL_SSL',
        mechanism: 'PLAIN',
        username: 'kafka_user',
        ssl_verify: false
      )
    end
  end

  describe '#schema_registry_config' do
    it 'returns configured schema registry settings' do
      provider.prepare
      config = provider.schema_registry_config
      expect(config).to include(
        url: 'schema-registry:8081',
        auth: {
          username: 'registry_user',
          password: 'registry_password'
        }
      )
    end
  end
end 