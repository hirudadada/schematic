# StarRocks Routine Load Feature Changelog

## Features
### Core Functionality
- Added Routine Load deployment support with migration-style versioning
- Support for SQL and YAML configuration formats
- Support for multiple operations (create, pause, resume, stop, alter)
- Migration tracking in database for deployment history

### Default Properties
- Configured optimal default properties:
  - desired_concurrent_number: 3
  - format: json
  - max_error_number: 0
  - max_filter_ratio: 1.0
  - max_batch_interval: 10
  - max_batch_rows: 2000000
  - task_consume_second: 15
  - task_timeout_second: 60

### Type System
- Added dry-types based type checking
- Type validation for all configurations
- Strict type checking for sensitive data
- Type-safe deployment operations

### Template Generation
- Added SQL template generation with placeholders for sensitive data
- Added YAML config template generation
- Support for different operations in template generation
- Default columns and jsonpaths configuration

### Deployment System
- Added deployment strategies (AutoStop and UserDefined)
- Support for hydration of sensitive data
- Configurable hydration (enabled by default, can be disabled)
- Transaction support for deployment operations

### Environment Configuration
- Added cluster configuration support (Kafka and Schema Registry)
- Database-specific environment configuration
- Support for development and production environments
- Configmap generation for production deployments

### File Structure

```plaintext
project.tmpl/src/starrocks/
└── db/
└── routine_loads/ # Routine load SQL and YAML files
├── create_.sql
├── pause_.sql
├── resume_.sql
├── stop_.sql
└── alter_.sql
docker/build/src/lib/schematic/starrocks/
├── deployables/
│ ├── strategies/ # Deployment strategies
│ ├── routine_load_.rb # Deployable implementations
│ └── hydratable_.rb # Hydratable versions
├── generator/ # GitOps config generation
├── templates/ # Template generation
└── providers/ # Environment configuration
```

### Environment Files

```plaintext
docker/
├── make.env/
│ └── starrocks/
│ └── cluster.env # Kafka and Schema Registry config
└── deploy/env/
└── cluster.env # Development environment mapping
```


## Commands

````bash
# Create new routine load
rake starrocks:routine_load:generate[create:table_name,sql]
rake starrocks:routine_load:generate[create:table_name,yaml]
# Create with specific operation
rake starrocks:routine_load:generate[pause,table_name,sql]
rake starrocks:routine_load:generate[resume,table_name,sql]
rake starrocks:routine_load:generate[stop,table_name,sql]
rake starrocks:routine_load:generate[alter,table_name,sql]
# Deploy routine loads
rake starrocks:routine_load:deploy
```

## Configuration Options
- Hydration: Enabled by default, can be disabled with `hydrate: false`
- Configmap Generation: Automatic in production, optional in development
- Environment Variables: Customizable through cluster.env
- Template Placeholders: Mustache-style syntax for sensitive data

# StarRocks Routine Load Migrations

## Migration Format
- Timestamp: YYYYMMDDHHMMSS
- Operation: create/alter/pause/resume/stop
- Table Name: target table
- Example: `20241101000000_create_users_routine_load.yaml`

## Applied Migrations
- Initial version: Migration-based deployment system
- Added routine load state tracking
- Added migration tracking table
