# StarRocks Routine Load Management

## Overview

This guide describes how to manage routine loads in StarRocks using migrations and GitOps configurations.

## Prerequisites

- StarRocks cluster
- Kafka cluster
- Schema Registry (optional)
- Ruby environment

## Setup

1. **Directory Structure**
```
project/
├── db/
│   └── starrocks/
│       └── routine_loads/
│           ├── migrations/     # For migration mode
│           │   ├── YYYYMMDDHHMMSS_create_example_table_routine_load.yaml
│           │   ├── YYYYMMDDHHMMSS_alter_example_table_routine_load.sql
│           │   └── ...
│           └── example_table_routine_load.sql  # For direct mode
└── gitops/
    └── overlays/
        └── dev/
            └── configmap/
                ├── routine-load-credentials.yaml
                └── routine-load-properties.yaml
```

2. **Environment Configuration**
```env
# StarRocks Connection
DB_HOST=localhost
DB_PORT=9030
DB_USER=root
DB_PASSWORD=
DB_NAME=schematic
DB_ADAPTER=mysql2

# Kafka Configuration
KAFKA_BROKER_LIST=broker1:9092,broker2:9092
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
KAFKA_SASL_USERNAME=kafka_user
KAFKA_SASL_PASSWORD=
KAFKA_SSL_VERIFY=false
KAFKA_PARTITIONS=0,1,2
KAFKA_OFFSET=OFFSET_BEGINNING

# Schema Registry Configuration
SCHEMA_REGISTRY_URL=schema-registry:8081
SCHEMA_REGISTRY_USERNAME=registry_user
SCHEMA_REGISTRY_PASSWORD=

# Routine Load Properties
ROUTINE_LOAD_CONCURRENT_NUMBER=3
ROUTINE_LOAD_FORMAT=json
ROUTINE_LOAD_MAX_ERROR_NUMBER=0
ROUTINE_LOAD_MAX_FILTER_RATIO=1.0
ROUTINE_LOAD_MAX_BATCH_INTERVAL=10
ROUTINE_LOAD_MAX_BATCH_ROWS=2000000
ROUTINE_LOAD_TASK_CONSUME_SECOND=15
ROUTINE_LOAD_TASK_TIMEOUT_SECOND=60

# Deployment Configuration
MIGRATION_MODE=true  # Set to false for Direct Mode
HYDRATE=true        # Must be true for encrypted credentials
RESOURCE_DIR=db/starrocks
WORK_DIR=db/starrocks
LOG_LEVEL=1         # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
SQL_LOG_LEVEL=debug  # debug, info, warn, error

# Retry Configuration
RETRY_MAX_ATTEMPTS=3
RETRY_BASE_DELAY=2
```

## Usage

### 1. Generate Migration Files

```bash
# Generate YAML migration (recommended)
rake starrocks:routine_load:generate[table_name,create,yaml]
rake starrocks:routine_load:generate[table_name,alter,yaml]
rake starrocks:routine_load:generate[table_name,pause,yaml]
rake starrocks:routine_load:generate[table_name,resume,yaml]
rake starrocks:routine_load:generate[table_name,stop,yaml]

# Or generate SQL migration
rake starrocks:routine_load:generate[table_name,create,sql]
```

### 2. Edit Migration Files

For YAML migrations:
```yaml
# 20240107000000_create_example_table_routine_load.yaml
:table: example_table
:routine_name: example_table_rl
:operation: :create
:columns:
  - uid
  - column1
  - column2
:kafka:
  :broker_list: "{{KAFKA_BROKER_LIST}}"
  :topic: example_table
  :partitions: "{{KAFKA_PARTITIONS}}"
  :offset: "{{KAFKA_OFFSET}}"
  :security:
    :protocol: "{{KAFKA_SECURITY_PROTOCOL}}"
    :mechanism: "{{KAFKA_SASL_MECHANISM}}"
    :username: "{{KAFKA_SASL_USERNAME}}"
    :password: "{{KAFKA_SASL_PASSWORD}}"
    :ssl_verify: "{{KAFKA_SSL_VERIFY}}"
:schema_registry:
  :url: "{{SCHEMA_REGISTRY_URL}}"
  :auth:
    :username: "{{SCHEMA_REGISTRY_USERNAME}}"
    :password: "{{SCHEMA_REGISTRY_PASSWORD}}"
```

For SQL migrations:
```sql
-- 20240107000000_create_example_table_routine_load.sql
CREATE ROUTINE LOAD `example_table_rl` ON `example_table`
COLUMNS TERMINATED BY ',',
COLUMNS (uid, column1, column2)
PROPERTIES
(
  "desired_concurrent_number" = "3",
  "format" = "json",
  "max_error_number" = "0",
  "max_filter_ratio" = "1.0",
  "max_batch_interval" = "10",
  "max_batch_rows" = "2000000",
  "task_consume_second" = "15",
  "task_timeout_second" = "60"
)
FROM KAFKA
(
  "kafka_broker_list" = "{{KAFKA_BROKER_LIST}}",
  "kafka_topic" = "example_table",
  "property.security.protocol" = "{{KAFKA_SECURITY_PROTOCOL}}",
  "property.sasl.mechanism" = "{{KAFKA_SASL_MECHANISM}}",
  "property.sasl.username" = "{{KAFKA_SASL_USERNAME}}",
  "property.sasl.password" = "{{KAFKA_SASL_PASSWORD}}",
  "property.enable.ssl.certificate.verification" = "{{KAFKA_SSL_VERIFY}}",
  "confluent.schema.registry.url" = "https://{{SCHEMA_REGISTRY_USERNAME}}:{{SCHEMA_REGISTRY_PASSWORD}}@{{SCHEMA_REGISTRY_URL}}",
  "property.basic.auth.credentials.source" = "USER_INFO",
  "kafka_partitions" = "{{KAFKA_PARTITIONS}}",
  "property.kafka_default_offsets" = "{{KAFKA_OFFSET}}"
);
```

### 3. Deploy Routine Loads

```bash
# Deploy with migration mode (default)
rake starrocks:routine_load:deploy

# Deploy without migration tracking
MIGRATION_MODE=false rake starrocks:routine_load:deploy
```

### 4. Check Status

```bash
rake starrocks:routine_load:status
```

This shows:
- Applied migrations
- Current routine loads and their states
- Any errors during deployment

## Operation Flow

1. **Create Operation**
   - Generates migration file
   - Validates configuration
   - Stops existing routine load if any
   - Creates new routine load
   - Records migration if in migration mode

2. **Alter Operation**
   - Requires routine load to be paused
   - Updates properties
   - Records migration if in migration mode

3. **Pause/Resume/Stop Operations**
   - Direct state management
   - Records migration if in migration mode

## GitOps Integration

The integration generates two configmaps:
1. `routine-load-credentials.yaml`: Contains Kafka and Schema Registry credentials
2. `routine-load-properties.yaml`: Contains routine load settings

Generate GitOps configurations:
```bash
rake starrocks:gitops:generate
```

## Error Handling

The deployment will retry if:
- SQL syntax errors
- Invalid configurations
- Connection issues
- State validation errors (e.g., altering without pausing)

## Retry Configuration

Control retry behavior through environment variables:

- `RETRY_MAX_ATTEMPTS`: Maximum number of retry attempts (default: 3)
- `RETRY_BASE_DELAY`: Base delay in seconds between retries (default: 2)

The actual delay uses exponential backoff: base_delay * retry_number
