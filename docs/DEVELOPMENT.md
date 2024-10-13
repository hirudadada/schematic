# Development Workflow

- [Development Workflow](#development-workflow)
  - [List of Available Rake Tasks](#list-of-available-rake-tasks)
    - [MSSQL Tasks](#mssql-tasks)
    - [Starrocks Tasks](#starrocks-tasks)
  - [Creating Database Migrations](#creating-database-migrations)
  - [Deploying Migrations](#deploying-migrations)
  - [Creating and Deploying Stored Procedures](#creating-and-deploying-stored-procedures)
  - [Creating and Deploying SQL Server Jobs](#creating-and-deploying-sql-server-jobs)
  - [Deploying to Multiple Database Targets](#deploying-to-multiple-database-targets)
  - [Generating Cipher Keys and GitOps Config](#generating-cipher-keys-and-gitops-config)
  - [Building and Pushing Application Images](#building-and-pushing-application-images)
  - [Sequel Migration Script Format Conversion](#sequel-migration-script-format-conversion)

## List of Available Rake Tasks

Schematic provides a set of handy Rake tasks out-of-the-box:

```bash
rake -T
```

### MSSQL Tasks
```plaintext
/home/app # rake -T
rake app:env                           # Load environment settings
rake app:version                       # Show application version
rake check                             # Perform configuration checks
rake cipher:decrypt_env_var[env_var]   # Decrypt an environment variable
rake cipher:encrypt[string]            # Encrypt a string
rake cipher:encrypt_env_var[env_var]   # Encrypt an environment variable
rake cipher:generate_keys              # Generate cipher keys
rake db:applied_migration[steps,app]   # Show a given applied schema migration
rake db:applied_migrations[app]        # Show applied schema migrations
rake db:apply[steps,app]               # Apply last n migrations
rake db:clean[app]                     # Remove migrations
rake db:create_migration[name]         # Create a migration file with a timestamp and name
rake db:migrate[version,app]           # Run migrations
rake db:migration_to_apply[steps,app]  # Show a given schema migration to apply
rake db:migrations_to_apply[app]       # Show schema migrations to apply
rake db:redo[steps,app]                # Redo last n migrations
rake db:reset[app]                     # Remove migrations and re-run migrations
rake db:rollback[steps,app]            # Rollback last n migrations
rake db:test                           # Test database connection
rake deploy[app]                       # Run deployment
rake fn:create[name]                   # Create a functions template file
rake fn:deploy                         # Apply function
rake gitops:generate                   # Generate GitOps config
rake job:create[name]                  # Create job template files
rake job:deploy                        # Apply jobs
rake schematic:version                 # Show Schematic version
rake seed:create[name]                 # Create a seed data template file
rake seed:deploy                       # Load Seed data
rake sp:create[name]                   # Create a stored procedure template file
rake sp:deploy                         # Apply stored procedures
rake sqlsequel:conver                  # Conver a.sql from SQL format to sequel migration format
rake sqlsequel:create                  # Create source SQL format a.sql for conversion to sequel migration format
rake version                           # Show version info
rake vw:create[name]                   # Create a vies template file
rake vw:deploy                         # Apply views
```

### Starrocks Tasks
```plaintext
/home/app # rake -T
rake app:env                                            # Load environment settings
rake app:version                                        # Show application version
rake check                                              # Perform configuration checks
rake cipher:decrypt_env_var[env_var]                    # Decrypt an environment variable
rake cipher:encrypt[string]                             # Encrypt a string
rake cipher:encrypt_env_var[env_var]                    # Encrypt an environment variable
rake cipher:generate_keys                               # Generate cipher keys
rake db:applied_migration[steps,app]                    # Show a given applied schema migration
rake db:applied_migrations[app]                         # Show applied schema migrations
rake db:apply[steps,app]                                # Apply last n migrations
rake db:clean[app]                                      # Remove migrations
rake db:create_migration[name]                          # Create a migration file with a timestamp and name
rake db:migrate[version,app]                            # Run migrations
rake db:migration_to_apply[steps,app]                   # Show a given schema migration to apply
rake db:migrations_to_apply[app]                        # Show schema migrations to apply
rake db:redo[steps,app]                                 # Redo last n migrations
rake db:reset[app]                                      # Remove migrations and re-run migrations
rake db:rollback[steps,app]                             # Rollback last n migrations
rake db:test                                            # Test database connection
rake gitops:generate                                    # Generate GitOps config
rake schematic:version                                  # Show Schematic version
rake version                                            # Show version info
```

## Creating Database Migrations

After creating a new project, you'll likely want to create your database migration before any other development work:

```bash
rake db:create_migration[migration_name]
```

This command will create a new migration file under `src/db/migrations/your-project-name_your-app-name` with a timestamp and the specified name.

## Deploying Migrations

To apply the database migrations:

```bash
rake db:migrate
```

If this doesn't work, add database name

```bash
rake db:migrate[schematic]
```

## Creating and Deploying Stored Procedures

> [!NOTE] This feature is for SQL Server Only.

To create a new stored procedure template:

```bash
rake sp:create[stored_procedure_name]
```

This command will create a new stored procedure template file under `src/stored_procedures/your-project-name_your-app-name`.

You can edit the stored procedure file as needed, and then deploy it using the following command:

```bash
rake sp:deploy
```

## Creating and Deploying SQL Server Jobs

> [!NOTE] This feature is for SQL Server Only.

To create a new SQL Server job template:

```bash
rake job:create[job_name]
```

This command will create a new job template file under `src/jobs/your-project-name_your-app-name` and a corresponding environment template file under `docker/deploy/env/jobs`.

You can edit these files as needed, and then deploy the jobs using the following command:

```bash
rake job:deploy
```

## Deploying to Multiple Database Targets

> [!WARNING] This feature for Starrocks in Schematic is still under development.

Schematic supports deploying to multiple database targets defined in the `databases.yaml` file under the project's root directory.

To deploy to all defined database targets, run:

```bash
rake deploy
```

## Generating Cipher Keys and GitOps Config

To generate cipher keys for encrypting and decrypting sensitive credentials:

```bash
rake cipher:generate_keys
```

To generate GitOps configurations:

```bash
rake gitops:generate
```

The generated configurations will be placed under `src/gitops`.

## Building and Pushing Application Images

Before building and pushing the application images, ensure that the correct version is specified in the `src/VERSION` file.

To build the application image:

```bash
make build.app.rel
```

To push the application image to a repository:

```bash
docker tag your-image-tag your-repository/your-image:version
make push.app.rel
```

## Sequel Migration Script Format Conversion

> [!NOTE] This feature is for SQL Server Only.

Schematic provides a Rake task to convert SQL migration scripts to the Sequel migration format:

```bash
rake sqlsequel:create     # Create a source SQL format file for conversion
rake sqlsequel:convert    # Convert the SQL file to the Sequel migration format
```
