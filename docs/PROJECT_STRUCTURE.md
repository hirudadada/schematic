# Project Structure

## Overview

A typical Schematic project has the following structure:

```
project/
├── docker/
│   ├── build/              # Build configurations
│   ├── deploy/             # Deployment configurations
│   │   ├── env/           # Environment files
│   │   │   ├── database.env
│   │   │   ├── cluster.env
│   │   │   └── secret.env
│   │   └── scripts/       # Deployment scripts
│   └── make.env/          # Make environment files
├── src/
│   ├── db/
│   │   ├── migrations/    # Database migrations
│   │   └── starrocks/    # StarRocks configurations
│   │       └── routine_loads/
│   │           ├── migrations/  # Routine load migrations
│   │           └── properties/  # Routine load properties
│   ├── gitops/           # Generated GitOps configurations
│   │   └── overlays/
│   │       └── dev/
│   │           └── configmap/
│   ├── Gemfile          # Ruby dependencies
│   └── VERSION          # Application version
├── Makefile            # Build and deployment tasks
└── README.md           # Project documentation
```

## Key Components

### Docker Configuration
- `docker/build/`: Docker build configurations
- `docker/deploy/`: Deployment configurations and scripts
- `docker/make.env/`: Environment files for make targets

### Source Code
- `src/db/migrations/`: Database schema migrations
- `src/db/starrocks/`: StarRocks-specific configurations
  - `routine_loads/migrations/`: Routine load migration files
  - `routine_loads/properties/`: Routine load property files

### GitOps Configuration
- `src/gitops/`: Generated GitOps configurations
  - `overlays/dev/configmap/`: Environment-specific configmaps

### Environment Files
- `database.env`: Database connection settings
- `cluster.env`: Kafka and Schema Registry settings
- `secret.env`: Sensitive credentials

## File Types

### Migration Files
```
YYYYMMDDHHMMSS_migration_name.rb    # Database migrations
YYYYMMDDHHMMSS_routine_load_name.yaml  # Routine load migrations (YAML)
YYYYMMDDHHMMSS_routine_load_name.sql   # Routine load migrations (SQL)
```

### Configuration Files
```yaml
# Routine Load Properties
routine_load_properties.yaml
routine_load_credentials.yaml
```

### Environment Files
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=9030
DB_USER=root
DB_PASSWORD=
DB_NAME=schematic

# Kafka Configuration
KAFKA_BROKER_LIST=broker1:9092,broker2:9092
KAFKA_SECURITY_PROTOCOL=SASL_SSL
...
