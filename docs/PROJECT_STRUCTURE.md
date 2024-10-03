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
