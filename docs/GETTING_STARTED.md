# Getting Started with Schematic

## Prerequisites

Before you can start using Schematic, you'll need to have Docker and Docker Compose installed on your system.

### Docker

Schematic uses Docker containers for development and deployment. You'll need to have Docker installed on your system. You can download and install Docker from the official website: [https://www.docker.com/get-started](https://www.docker.com/get-started)


## Getting the Schematic Base Code

First, clone the Schematic repository:

```bash
# Forked from github.com/larryloi/schematic.git

git clone https://github.com/hirudadada/schematic.git
cd schematic
```

## Building or Pulling the `schematic_base` Image

### Building from Source Code

If you have an internet connection available, you can build the `schematic_base` image from the source code:

```bash
cd docker
make build.base.rc
```

### Pulling from Quay.io

If you only have access to the Docker repository, you can pull the `schematic_base` image from Quay.io:

If not already logged in, then
```bash
docker login quay.io
```

Pull the image
```bash
docker pull quay.io/larryloi/schematic_base:latest
docker pull quay.io/larryloi/schematic_base:0.8.3-rc.1
```

## Creating a New Project

To create a new project, execute the following command from the Schematic home directory:

```bash
# For SQL Server
make create.project.mssql project=your-project-name app=your-app-name target=/path/to/target/directory

# For PostgreSQL
make create.project.psql project=your-project-name app=your-app-name target=/path/to/target/directory

# For Starrocks
make create.project.starrocks project=your-project-name app=your-app-name target=/path/to/target/directory
```

## Starting the Project Containers

1. Open the new project folder (`/path/to/target/directory/your-project-name_your-app-name`).
2. Set the database password by editing the `secret.env` file under `docker/make.env/mssql/secret.env` (or `psql/secret.env`, `starrocks/secret.env` depending on your database).
3. Start the containers:

```bash
cd docker
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
make shell.dev
```
