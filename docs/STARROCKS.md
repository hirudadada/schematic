# Starrocks in Schematic

## Starrocks Migration Conventions

Since the Sequel gem does not have a Starrocks adapter, the migration files for Starrocks require raw SQL statements.

To create a new Starrocks migration:

```bash
rake db:create_migration[migration_name]
```

This command will create a new migration file under `src/db/migrations/your-project-name_your-app-name` with a timestamp and the specified name.

Here's an example of a Starrocks table migration script:

```ruby
# frozen_string_literal: true

# db/migrations/20240930040354_example_create_table.rb
Sequel.migration do
  up do
    execute(<<~SQL)
      CREATE TABLE example_table (
          order_id BIGINT,
          order_date DATE,
          customer_id INT,
          total_amount DECIMAL(10,2)
      )
      ENGINE=olap
      PRIMARY KEY (order_id, order_date, customer_id)
      PARTITION BY RANGE (order_date)
      (
          PARTITION p201901 VALUES LESS THAN ('2019-02-01'),
          PARTITION p201902 VALUES LESS THAN ('2019-03-01')
      )
      DISTRIBUTED BY HASH(order_id, order_date, customer_id)
      ORDER BY (order_date, customer_id);
    SQL
  end

  down do
    execute(<<~SQL)
      DROP TABLE IF EXISTS example_table;
    SQL
  end
end
```

## Showing Migrations to Apply

To show the migrations that are pending to be applied:

```bash
rake db:migrations_to_apply
```

## Deploying Migrations for Starrocks

To deploy the Starrocks migrations:

```bash
rake db:migrate
```

## Routine Load Management

### Default Properties
StarRocks Routine Load comes with the following default properties:
```yaml
# Default Routine Load Properties
desired_concurrent_number: 3      # Number of concurrent tasks
format: json                      # Data format
max_error_number: 0              # Maximum number of errors allowed
max_filter_ratio: 1.0            # Maximum filter ratio
max_batch_interval: 10           # Maximum batch interval in seconds
max_batch_rows: 2000000          # Maximum rows per batch
task_consume_second: 15          # Task consume timeout in seconds
task_timeout_second: 60          # Task execution timeout in seconds
```

These defaults can be overridden through:
1. Environment variables in `cluster.env`
2. YAML configuration files
3. SQL ALTER statements

### Migration-Style Deployment
Routine Load configurations are managed using a migration-based approach:

```bash
# Generate a new routine load migration
rake starrocks:routine_load:generate[table_name,operation,format]

# Example:
rake starrocks:routine_load:generate[users,create,yaml]
# Creates: YYYYMMDDHHMMSS_create_users_routine_load.yaml
```

### Checking Status
To check the status of routine loads and migrations:

```bash
rake starrocks:routine_load:status
```

This shows:
- Applied migrations history
- Current routine load states
- Deployment timestamps

### Database Setup
During initial setup, Schematic creates:
1. Schema migrations table
2. Routine load migrations table
3. Required database structures
