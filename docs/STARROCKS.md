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
      CREATE TABLE testing (
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
      DROP TABLE IF EXISTS testing;
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