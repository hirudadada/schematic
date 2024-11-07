# Schematic

A database deployment and management tool supporting multiple databases and deployment strategies.

## Features

### Database Support
- **MSSQL**
  - Stored Procedures deployment
  - SQL Server Jobs management
  - Migration tracking
- **StarRocks**
  - Routine Load management
  - Migration-based deployments
  - Direct mode operations

### Core Features
- Migration-based deployment system
- Type-safe configurations
- Secure credential management
- GitOps integration
- Multiple deployment strategies
- Environment-specific configurations

## Quick Start

### Project Creation
```bash
# Create new StarRocks project
make create.project.starrocks project=test app=sample target=../

# Create new MSSQL project
make create.project.mssql project=test app=sample target=../

# Generate database migration
rake db:create_migration[create_users]

# Deploy database changes
rake db:migrate
```

### Project Structure
After creation, your project will have:
```
test/                          # Project root
├── docker/                    # Docker configurations
│   ├── build/                # Build configurations
│   ├── deploy/               # Deployment configurations
│   │   └── env/             # Environment files
│   └── make.env/            # Make environment files
└── src/                      # Source code
    ├── db/                   # Database files
    │   └── starrocks/       # StarRocks specific
    │       └── routine_loads/# Routine Load configs
    ├── gitops/              # Generated GitOps configs
    └── Gemfile              # Ruby dependencies
```

### MSSQL Features
```bash
# Generate stored procedure
rake sp:create[user_management]

# Deploy stored procedures
rake sp:deploy

# Create job
rake job:create[daily_cleanup]

# Deploy jobs
rake job:deploy
```

### StarRocks Features
```bash
# Generate routine load migration
rake starrocks:routine_load:generate[users,create,yaml]

# Deploy routine loads
rake starrocks:routine_load:deploy

# Check status
rake starrocks:routine_load:status
```

### GitOps Configuration
```bash
# Generate GitOps configs
rake gitops:generate
```

## Development

### Environment Setup
```bash
# Start development environment
make up

# Access development shell
make shell

# Run tests
make test
```

### Building and Deployment
```bash
# Build release image
make build.app.rel

# Push release image
make push.app.rel
```

## Documentation

- [Development Guide](docs/DEVELOPMENT.md)
- [StarRocks Guide](docs/STARROCKS.md)
- [Project Structure](docs/PROJECT_STRUCTURE.md)
- [Changelog](docs/CHANGELOG.md)

## Configuration

### Environment Variables
```env
# Database Connection
DB_HOST=localhost
DB_PORT=1433  # MSSQL default
DB_USER=sa
DB_PASSWORD=
DB_NAME=schematic

# Deployment Settings
MIGRATION_MODE=true
HYDRATE=true
LOG_LEVEL=1  # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
```

### Security
```bash
# Generate cipher keys
rake cipher:generate_keys

# Encrypt sensitive data
rake cipher:encrypt[mypassword]
```

## Project Structure
```
project/
├── db/
│   ├── migrations/           # Database migrations
│   ├── mssql/               # MSSQL specific
│   │   ├── jobs/           # SQL Server Jobs
│   │   └── procedures/     # Stored Procedures
│   └── starrocks/          # StarRocks specific
│       └── routine_loads/  # Routine Load configs
├── gitops/                 # Generated GitOps configs
└── docker/                # Docker configurations
```
