# Project Structure

Here's the project folder structure for a sample Schematic project:

```
your-project-name_your-app-name
├── CHANGELOG.md
├── README.md
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
│       ├── dev_image.env
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

For StarRocks projects, additional structures include:
```
your-project-name_your-app-name
└── src
    └── starrocks
        └── db
            ├── migrations/           # Database migrations
            └── routine_loads/        # Routine Load migrations
                └── migrations/       # Migration-style routine loads
                    ├── YYYYMMDDHHMMSS_create_table_routine_load.yaml
                    ├── YYYYMMDDHHMMSS_alter_table_routine_load.yaml
                    └── YYYYMMDDHHMMSS_pause_table_routine_load.yaml

docker
├── deploy
│   └── starrocks
│       └── scripts
│           ├── create_initial_database.sh
│           ├── create_schema_migration_table.sh
│           └── create_routine_load_migrations_table.sh
└── make.env
    └── starrocks
        ├── database.env
        ├── secret.env
        └── cluster.env             # Kafka and Schema Registry configuration
```
