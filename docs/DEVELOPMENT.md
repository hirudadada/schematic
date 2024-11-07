# Development Workflow

## List of Available Rake Tasks

Schematic provides a set of handy Rake tasks out-of-the-box:

```bash
rake -T
```

## Database Management

### Migration Tasks
```plaintext
rake db:create_migration[name]         # Create a migration file
rake db:migrate[version,app]           # Run migrations
rake db:rollback[steps,app]            # Rollback migrations
rake db:reset[app]                     # Reset and re-run migrations
rake db:status                         # Show migration status
```

Migration files are versioned and tracked in the database:
```ruby
# db/migrations/YYYYMMDDHHMMSS_create_example_table.rb
Sequel.migration do
  up do
    create_table(:example) do
      primary_key :id
      String :name, null: false
      DateTime :created_at
    end
  end

  down do
    drop_table(:example)
  end
end
```

### MSSQL Features

#### Stored Procedures
```plaintext
rake sp:create[name]                   # Create stored procedure template
rake sp:deploy                         # Deploy stored procedures
```

Stored procedures are managed in versioned files:
```sql
-- db/mssql/stored_procedures/YYYYMMDDHHMMSS_example_procedure.sql
CREATE OR ALTER PROCEDURE [dbo].[example_procedure]
    @param1 INT,
    @param2 VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Procedure logic here
END
```

#### SQL Server Jobs
```plaintext
rake job:create[name]                  # Create job template
rake job:deploy                        # Deploy jobs
```

Jobs are configured in YAML files:
```yaml
# db/mssql/jobs/example_job.yml
name: ExampleJob
enabled: true
schedule:
  frequency: daily
  start_time: "02:00"
steps:
  - name: ExecuteStoredProcedure
    type: tsql
    command: EXEC [dbo].[example_procedure] @param1=1, @param2='test'
```

### StarRocks Features

#### Routine Load Management
```plaintext
rake starrocks:routine_load:generate   # Generate routine load migration
rake starrocks:routine_load:deploy     # Deploy routine loads
rake starrocks:routine_load:status     # Show routine load status
```

Routine loads can be managed in two modes:
1. **Migration Mode** (Default)
   - Versioned migrations in `db/starrocks/routine_loads/migrations/`
   - Tracked in `routine_load_migrations` table
   - Ensures idempotent deployments
   ```bash
   # Generate and deploy migrations
   rake starrocks:routine_load:generate[table_name,create,yaml]
   rake starrocks:routine_load:deploy
   ```

2. **Direct Mode**
   - Direct operations in `db/starrocks/routine_loads/`
   - No migration tracking
   - Best for one-off operations
   ```bash
   # Deploy without migration tracking
   MIGRATION_MODE=false rake starrocks:routine_load:deploy
   ```

For detailed StarRocks routine load management, see [StarRocks Guide](STARROCKS.md).

## Configuration and Security

### Environment Setup
```bash
rake app:env                           # Load environment settings
rake check                            # Perform configuration checks
```

### Cipher Management
```bash
rake cipher:generate_keys             # Generate cipher keys
rake cipher:encrypt[string]           # Encrypt a string
rake cipher:decrypt_env_var[env_var]  # Decrypt an environment variable
```

Sensitive data can be encrypted:
```bash
# Encrypt a password
rake cipher:encrypt[mypassword]
# Use in environment files
DB_PASSWORD_ENCRYPTED=encrypted_string
```

### GitOps Configuration
```bash
rake gitops:generate                  # Generate GitOps config
```

Generates Kubernetes configmaps for:
- Database credentials
- MSSQL job configurations
- StarRocks routine load settings

## Building and Deployment

### Building Images
```bash
# Build release image
make build.app.rel

# Build development image
make build.app.dev
```

### Pushing Images
```bash
# Push release image
make push.app.rel

# Push development image
make push.app.dev
```

### Development Environment
```bash
# Start development containers
make up

# Access development shell
make shell

# Run tests
make test
```

For more details on specific features:
- [StarRocks Guide](STARROCKS.md)
- [Getting Started](GETTING_STARTED.md)
- [Project Structure](PROJECT_STRUCTURE.md)
