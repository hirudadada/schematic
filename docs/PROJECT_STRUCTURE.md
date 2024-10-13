# Project Structure

Here's the project folder structure for a sample Schematic project:

```
your-project-name_your-app-name
```

## Setup a Schematic project

First, clone Schematic:

```bash
# forked from https://github.com/larryloi/schematic
git clone https://github.com/hirudadada/schematic
cd schematic
```

Then, make a new project:

```bash
# MSSQL
make create.project.mssql project=test app=sample target=/root/to/projects

# PostgreSQL
make create.project.psql project=test app=sample target=/root/to/projects

# Starrocks
make create.project.starrocks project=test app=sample target=/root/to/projects
```

## Starting the Project Containers

1. Open the new project folder (`/path/to/target/directory/your-project-name_your-app-name`).
2. Set the database password by editing the `secret.env` file under `docker/make.env/mssql/secret.env` (or `psql/secret.env`, `starrocks/secret.env` depending on your database).
3. Start the containers:

```bash
cd docker
```

First run: 

```bash
cd docker && make build.app.dev
```

Starting the container

```bash
make up
```

## Setting up the Database

If you're using SQL Server or PostgreSQL, you need to create the development database before proceeding:

```bash
make shell.dev.db
```

Now you're in the shell of the database container

```bash
./setup-db.sh
```

> [!NOTE] if you're using StarRocks
> run these instead
> ```bash
> ./create_initial_database.sh
> ./create_migration_table.sh
> ```

Then exit the DB container
```bash
exit
```

Finally, you can start your development locally inside the `dev.app` container:

```bash
make shell.app.dev
```

## Development features

### List Rake tasks available

Schematic provides a few handy Rake tasks out-of-box:

```
rake -T

rake cipher:decrypt_env_var[env_var]  # Decrypt an environment variable
rake cipher:encrypt[string]           # Encrypt a string
rake cipher:encrypt_env_var[env_var]  # Encrypt an environment variable
rake cipher:generate_keys             # Generate cipher keys
rake db:applied_migration[steps]      # Show a given applied schema migration
rake db:applied_migrations            # Show applied schema migrations
rake db:apply[steps]                  # Apply last n migrations
rake db:clean                         # Remove migrations
rake db:create_migration[name]        # Create a migration file with a timestamp and name
rake db:migrate[version]              # Run migrations
rake db:migration_to_apply[steps]     # Show a given schema migration to apply
rake db:migrations_to_apply           # Show schema migrations to apply
rake db:redo[steps]                   # Redo last n migrations
rake db:reset                         # Remove migrations and re-run migrations
rake db:rollback[steps]               # Rollback last n migrations
rake deploy                           # Run deployment
```

### Create a database migration

After a new project is created, it is most likely to create your database migration before any other development work:

```
rake db:create_migration[name=create_samples]

New migration is created: /home/app/db/migrations/schematic/20231019015901_create_samples.rb
```

To apply the database migration:

```
rake db:migrate
```

### Configuration management

Global project configurations can be managed under the folder `/docker/make.env`

  * `project.env` - project-wide configurations
  * `docker.env` - docker container configurations
    * To set up the image registry configuration
    * To use a newer version of Schematic
    * To use a different database type (default: MSSQL)
  * `cipher.env` - cipher configurations
  * Database folder like `mssql`, `psql`, or `starrocks` - database configurations
    * `docker.env` - database container configurations
    * `secret.env` - database credential configurations
      * This file will be ignored by Git by default
      * No credentials should be checked into the source repo

### Credential management

Schematic provides handy Rake tasks to protect sensitive credentials like database passwords.

> [!NOTE] StarRocks docker image has no password for root.

First, generate RSA key pairs if not done yet:

```
rake cipher:generate_keys

Saving private Key (/home/app/.cipher/schematic.priv) ... done
Saving public key (/home/app/.cipher/schematic.pub) ...done
```

Then, you can encrypt your credentials via environment variables.

Assume you have set up an environment variable, `DEV_DB_PASSWORD`, in the secret file `docker/make.env/mssql/secret.env` (or `psql/secret.env`, or `starrocks/secret.env`). In the dev container, another environment variable, `DB_PASSWORD`, is used to hold the value of `DEV_DB_PASSWORD`. You can generate the encrypted database password by running:

```
rake cipher:encrypt_env_var[DB_PASSWORD]
Rv1ZR50pW7XAG6/6LNhNM7uAdtz4J0v6jgFcA1bGN/DNOcr......+013DhDuMwRDmUKjyrp9SM6kAnAAxMbKEpSrrCsMIA=
```

Please save the encrypted string (Base64 encoded) to an environment variable, `DEV_DB_PASSWORD_ENCRYPTED`, in the secret file (`docker/make.env/mssql/secret.env`, `psql/secret.env`, or `starrocks/secret.env`):

```
DEV_DB_PASSWORD_ENCRYPTED=Rv1ZR50pW7XAG6/6LNhNM7uAdtz4J0v6jgFcA1bGN/DNOcr......+013DhDuMwRDmUKjyrp9SM6kAnAAxMbKEpSrrCsMIA=
```

Last, you need to restart your containers to make it effective:

```
make down

make up
```

### Build and push project image

To build the project image for QA after development is done:

1. Update VERSION (`/path/to/target/directory/your-project-name_your-app-name`), 
   (or build number as well).
2. Build image.
3. Push image.

```
make build.app.dev
make push.app.dev
```

To build the project image for production when it is ready to go live:

```
make build.app.rel
make push.app.rel
```

## Project folder structure

Here is the project folder structure for a sample project:

```
test_sample
├── CHANGELOG.md
├── README.md
├── VERSION
├── docker
│   ├── Makefile
│   ├── Makefile.env
│   ├── build
│   │   ├── dev
│   │   │   ├── Dockerfile
│   │   │   ├── Makefile
│   │   │   └── build.env
│   │   ├── rel
│   │   │   ├── Dockerfile
│   │   │   ├── Makefile
│   │   │   └── build.env
│   │   └── shared
│   │       ├── build.env
│   │       └── build.mk
│   ├── deploy
│   │   ├── docker-compose.yaml
│   │   ├── env
│   │   │   ├── cipher.env
│   │   │   ├── database.env
│   │   │   ├── jobs
│   │   │   │   └── general.env
│   │   │   └── secret.env
│   │   └── mssql
│   │       ├── docker-compose.yaml
│   │       └── scripts
│   │           ├── mssql.sh
│   │           ├── setup-db.sh
│   │           └── sql
│   │               └── setup-db.sql
│   └── make.env
│       ├── base_image.env
│       ├── cipher.env
│       ├── database.env
│       ├── docker.env
│       ├── mssql
│       │   ├── database.env
│       │   └── secret.env
│       ├── psql
│       │   ├── database.env
│       │   └── secret.env
│       ├── starrocks
│       │   ├── database.env
│       │   └── secret.env
│       └── project.env
└── src
    ├── Rakefile
    ├── db
    │   └── migrations
    ├── jobs
    │   └── general.yaml
    └── stored_procedures
```
