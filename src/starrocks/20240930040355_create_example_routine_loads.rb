# frozen_string_literal: true

require 'yaml'
require 'fileutils'

def generate_migration_version(timestamp = Time.now.strftime('%Y%m%d%H%M%S'))
  timestamp
end

# Helper to generate routine load YAML content
def generate_routine_load_yaml(table_number)
  routine_name = "example_table_#{table_number}_rl"
  table_name = "example_table_#{table_number}"

  base_columns = [
    'id',
    'created_at',
    'name',
    'description',
    'value',
    'updated_at'
  ]

  extra_columns = case table_number % 3
                 when 0
                   ['category', 'price']
                 when 1
                   ['active', 'status']
                 when 2
                   ['quantity', 'location']
                 end

  {
    table: table_name,
    routine_name: routine_name,
    db: 'schematic',
    operation: :create,
    columns: base_columns + extra_columns,
    kafka: {
      broker_list: '{{KAFKA_BROKER_LIST}}',
      topic: table_name,
      partitions: '{{KAFKA_PARTITIONS}}',
      offset: '{{KAFKA_OFFSET}}',
      security: {
        protocol: '{{KAFKA_SECURITY_PROTOCOL}}',
        mechanism: '{{KAFKA_SASL_MECHANISM}}',
        username: '{{KAFKA_SASL_USERNAME}}',
        password: '{{KAFKA_SASL_PASSWORD}}',
        ssl_verify: '{{KAFKA_SSL_VERIFY}}'
      }
    },
    schema_registry: {
      url: '{{SCHEMA_REGISTRY_URL}}',
      auth: {
        username: '{{SCHEMA_REGISTRY_USERNAME}}',
        password: '{{SCHEMA_REGISTRY_PASSWORD}}'
      }
    },
    properties: {
      desired_concurrent_number: '3',
      format: 'json',
      max_error_number: '0',
      max_filter_ratio: '1.0',
      max_batch_interval: '10',
      max_batch_rows: '2000000',
      task_consume_second: '15',
      task_timeout_second: '60',
      max_batch_size: '2000000',
      jsonpaths: base_columns.map { |col| "$.#{col}" } + 
                 extra_columns.map { |col| "$.#{col}" }
    }
  }
end

# Create directory if it doesn't exist
routine_loads_dir = File.join('db', 'starrocks', 'routine_loads', 'migrations')
FileUtils.mkdir_p(routine_loads_dir)

# Generate 30 routine load YAML files
(1..30).each do |i|
  timestamp = generate_migration_version
  sleep(1) # Ensure unique timestamps
  
  filename = File.join(
    routine_loads_dir, 
    "#{timestamp}-create-schematic-example_table_#{i}-routine-load.yaml"
  )
  
  File.write(filename, generate_routine_load_yaml(i).to_yaml)
  puts "Generated #{filename}"
end 
