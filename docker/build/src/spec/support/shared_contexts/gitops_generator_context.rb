RSpec.shared_context "gitops generator context" do
  include_context "error handling routine load context"
  include FixturesHelper

  let(:configmap_dir) { fixture_path('gitops/overlays/dev/configmap') }
  let(:templates_dir) { File.expand_path('../../../lib/schematic/starrocks/generator/gitops/templates', __dir__) }

  let(:mock_provider) do
    Class.new(Schematic::Starrocks::Providers::RoutineLoadConfigProvider) do
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
          }
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
    end.new
  end

  before(:each) do
    FileUtils.mkdir_p(configmap_dir)
    
    # Allow any ENV variable to be accessed, with a default value of nil
    allow(ENV).to receive(:[]).and_return(nil)
    
    # Stub specific ENV variables that we know we need
    allow(ENV).to receive(:[]).with('STARROCKS_RESOURCE_DIR').and_return(fixture_path('gitops'))
    allow(ENV).to receive(:[]).with('KAFKA_BROKER_LIST').and_return('localhost:9092')
    allow(ENV).to receive(:[]).with('KAFKA_SECURITY_PROTOCOL').and_return('PLAINTEXT')
    allow(ENV).to receive(:[]).with('KAFKA_SASL_MECHANISM').and_return('PLAIN')
    allow(ENV).to receive(:[]).with('KAFKA_SASL_USERNAME').and_return('test_user')
    allow(ENV).to receive(:[]).with('KAFKA_SASL_PASSWORD').and_return('test_password')
    allow(ENV).to receive(:[]).with('KAFKA_SSL_VERIFY').and_return('false')
    allow(ENV).to receive(:[]).with('KAFKA_PARTITIONS').and_return('0,1,2')
    allow(ENV).to receive(:[]).with('KAFKA_OFFSET').and_return('OFFSET_BEGINNING')
    allow(ENV).to receive(:[]).with('SCHEMATIC_CIPHER_ALGORITHM').and_return('aes-256-gcm')
    allow(ENV).to receive(:[]).with('SCHEMATIC_CIPHER_KEY_LENGTH').and_return('32')
    allow(ENV).to receive(:[]).with('SCHEMATIC_CIPHER_ISSUER').and_return('test')
    allow(ENV).to receive(:[]).with('DB_USER').and_return('test_user')
    allow(ENV).to receive(:[]).with('DB_PASSWORD').and_return('test_password')
    allow(ENV).to receive(:[]).with('DB_HOST').and_return('localhost')
    allow(ENV).to receive(:[]).with('DB_NAME').and_return('test_db')
    allow(ENV).to receive(:[]).with('DB_TYPE').and_return('starrocks')
    allow(ENV).to receive(:[]).with('DB_ADAPTER').and_return('mysql2')
    allow(ENV).to receive(:[]).with('DATABASE_URL').and_return('mysql2://localhost/test_db')

    # Ensure the generator uses the correct template directory
    allow_any_instance_of(Schematic::Starrocks::Generator::RoutineLoadGitOpsConfig)
      .to receive(:routine_load_templates_dir)
      .and_return(templates_dir)
  end

  after(:each) do
    # Clean up any generated files in the fixtures directory
    FileUtils.rm_rf(Dir.glob(File.join(configmap_dir, '*')))
  end
end