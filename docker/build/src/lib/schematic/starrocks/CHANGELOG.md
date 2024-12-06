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

## [0.8.4]

### Database Compatibility
- Added support for StarRocks 3.2.10
  - Updated table creation syntax
  - Modified distribution and primary key definitions
  - Standardized table creation across modules
  - Improved backwards compatibility

### Table Definitions
- Updated schema_migrations table
  - Added DISTRIBUTED BY HASH clause
  - Standardized PRIMARY KEY definition
- Updated routine_load_migrations table
  - Removed NOT NULL constraints for flexibility
  - Added proper distribution definition
  - Standardized table creation syntax

## [0.8.5] (2024-11-07)

* Added Database Setup Module
  - Added base database setup functionality
  - Added StarRocks-specific table creation
  - Moved routine load migrations table setup
  - Improved initialization flow
* Enhanced Migration Strategy
  - Moved table creation to setup module
  - Improved error handling
  - Added consistent table initialization
* Updated Documentation
  - Added database setup details
  - Updated deployment flow documentation
  - Added initialization information

## [0.8.6] (2024-11-23)

### Error Handling for Developers
- Enhanced error handling for routine load operations
  - State transformation errors now provide clear messages
  - Connection errors include retry information
  - Improved logging for troubleshooting

### Common Error Scenarios & Solutions
1. State Transformation Errors
   ```sql
   -- Error: Cannot transform from RUNNING to PAUSED
   -- Solution: Check current state before pausing
   SHOW ROUTINE LOAD FROM `db_name` WHERE NAME = 'routine_name';
   ```

2. Connection Issues
   - System retries automatically (3 attempts)
   - Logs show retry attempts and connection status
   - Check StarRocks connectivity if persistent

3. Malformed Packet Errors
   - Usually temporary, system will retry
   - If persistent, verify SQL statement format
   - Check for special characters in routine names

### Logging Improvements
- Added detailed logging for error diagnosis
  - Current state logging before operations
  - Clear state transition messages
  - Connection retry attempt tracking
  - Error context in log messages

### Developer Guidelines
1. Error Handling Best Practices
   - Always check routine load state before operations
   - Use provided logging for troubleshooting
   - Allow retry mechanism to handle temporary issues

2. Deployment Recommendations
   - Use migration versioning for state changes
   - Monitor logs during deployments
   - Handle state conflicts gracefully

3. Testing Guidelines
   - Test state transitions thoroughly
   - Verify error handling in local environment
   - Use provided test helpers for common scenarios

## [0.8.7] (2024-11-26)

1. Consolidate retry mechanism
2. fix inconsistent naming module and update template generation

## [0.9.1] (2024-12-06)

* Changed syntax for create routine load to use CONCAT with dynamic sql, the 
hydrate flag and yaml creation option is deprecated.

