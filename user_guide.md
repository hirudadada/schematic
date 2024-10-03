# Introduction
An Rdb schema migration tools that develop on ruby and Supporting SQL Server and MySQL. This help you to deploy you database schema change. stored procedure and create or update agent job on SQL Server formally and solidly.


- [Introduction](#introduction)
  - [Getting the Schematic Base Code](#getting-the-schematic-base-code)
- [Functions](#functions)
- [Development, Testing phases](#development-testing-phases)
- [How to use it for development?](#how-to-use-it-for-development)
  - [Prepare New Project from template](#prepare-new-project-from-template)
    - [Get the schematic base code from github](#get-the-schematic-base-code-from-github)
    - [How to get schematic\_base image for development](#how-to-get-schematic_base-image-for-development)
    - [Create development project](#create-development-project)
  - [Start development in new project folder](#start-development-in-new-project-folder)
    - [Start project container](#start-project-container)
    - [Run database setup](#run-database-setup)
    - [Start development locally inside dev.app container](#start-development-locally-inside-devapp-container)
    - [Development features](#development-features)
      - [MSSQL Tasks](#mssql-tasks)
      - [Starrocks Tasks](#starrocks-tasks)
      - [If you encounter unkown database 'test\_sample' error](#if-you-encounter-unkown-database-test_sample-error)
  - [Database migration create and deploy](#database-migration-create-and-deploy)
    - [MSSQL \& PSQL](#mssql--psql)
  - [Starrocks migration convention](#starrocks-migration-convention)
    - [Showing migrations to apply](#showing-migrations-to-apply)
  - [MSSQL](#mssql)
    - [Stored Procedures create and deploy](#stored-procedures-create-and-deploy)
    - [SQL Server jobs create and deploy](#sql-server-jobs-create-and-deploy)
    - [Deploy all objects for a single DB target](#deploy-all-objects-for-a-single-db-target)
    - [Multi Target Database deployment](#multi-target-database-deployment)
    - [Generate cipher keys](#generate-cipher-keys)
    - [Generate GitOps config](#generate-gitops-config)
  - [Building/Push applicaiton images](#buildingpush-applicaiton-images)
    - [Sequel Migration script format conversion](#sequel-migration-script-format-conversion)
  - [Project folder structure](#project-folder-structure)

## Getting the Schematic Base Code

First, clone the Schematic repository:

```bash
# Forked from github.com/larryloi/schematic.git

git clone https://github.com/hirudadada/schematic.git
cd schematic
```

# Functions
- SQL Server, help to create database schema, and create SQL Server Agent jobs
- PostgreSQL, help to create database schema.

# Development, Testing phases
In development phase, we hope to have a environment that build up fast and work independent, with the tools here, build our self-contain a development environment and also prepare some sample data for testing purpose.

# How to use it for development?
The schematic base that contains core logic for schema, sp, jobs deployment but also help to create new project template for development. 
1. Clone Schematic and build the base image
2. Create New project by schematic project template

## Prepare New Project from template
### Get the schematic base code from github
**Get it by command**
```bash
cd /home/ds/_Devlopment/temp
git clone https://github.com/larryloi/schematic.git
```
**Or use VScode**
 1. Open Remote Explorer and connect Remote Host
 2. Clone Git Repository to /home/ds/_Devlopment/temp

### How to get schematic_base image for development
1. **Build from source code (Internet connection avaliable)**
   Run build image command
    ```bash
    cd schematic/docker
    make build.base.rel
    ```
1. **Pull image from Quay.io  (Only Docker repositry avaliable)**
    ```bash
    docker login quay.io

    docker pull quay.io/larryloi/schematic_base:latest
    
    docker pull quay.io/larryloi/schematic_base:0.2.5-rel.0
    ```
**The below schematic-base you will get**
```bash
ubt23 :: temp/schematic/docker ‹main› » docker images
REPOSITORY                        TAG                     IMAGE ID       CREATED        SIZE
quay.io/larryloi/schematic_base   0.2.5-rel               7a4144e23fd4   18 minutes ago   137MB
quay.io/larryloi/schematic_base   0.2.5-rel.0             7a4144e23fd4   18 minutes ago   137MB
```
### Create development project
In schematic home path, execute the below command, that creates project template for development. This project folder will be created in parent folder in this case.
```bash
cd schematic
make create.project.mssql project=data-staging app=acsc target=../
```


## Start development in new project folder
Open the New project folder ( In this case is data-staging_acsc )

We need to kick start the container that including dev.app and dev.db to devlop our code. Before that, set database password to evironment variable, ```MSSQL_SA_PASSWORD``` in ```secret.env``` file:
```bash
## MSSQL
vi docker/make.env/mssql/secret.env
```

The environment file 
```docker/make.env/base_image.env``` 

that indicated which base image to use for container startup. 
- ```DEV_BASE_IMAGE_VERSION``` 
- ```DEV_BASE_IMAGE_RELEASE_TAG``` 
may need to change accordingly.
```bash
cat docker/make.env/base_image.env

# Dev base image
DEV_BASE_IMAGE_NAME=schematic_base
DEV_BASE_IMAGE_VERSION=0.2.5
DEV_BASE_IMAGE_RELEASE_TAG=rel
DEV_BASE_IMAGE_BUILD_NUMBER=0
DEV_BASE_IMAGE_REPO=${IMAGE_REPO_ROOT}/${DEV_BASE_IMAGE_NAME}
DEV_BASE_IMAGE_TAG=${DEV_BASE_IMAGE_VERSION}-${DEV_BASE_IMAGE_RELEASE_TAG}.${DEV_BASE_IMAGE_BUILD_NUMBER}
DEV_BASE_IMAGE=${DEV_BASE_IMAGE_REPO}:${DEV_BASE_IMAGE_TAG}
```

### Start project container
The below command will start up container for ```dev.app``` and ```dev.db```
```bash
cd <Project-Path>/docker
make up
```
### Run database setup
```bash
make shell.dev

# Now you get into the shell of the database container
ruby ./scripts/setup-db.rb
exit
```
This ```setup-db.sql``` file use to prepare database setup for your development, for example, ```db```, ```schema``` and ```login``` setup. you may update as your need

```bash
<Project-Path>/docker/deploy/mssql/scripts/sql/setup-db.sql
```

### Start development locally inside dev.app container 
```bash
make shell.dev
```

### Development features
**List rake tasks avalable**
Schematic provides a few handy rake tasks out-of-box:

#### MSSQL Tasks
```bash
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

#### Starrocks Tasks
```bash
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
<!-- # rake starrocks:create_routine_load_config[config_name]  # Create a new Routine Load configuration -->

#### If you encounter unkown database 'test_sample' error

```zsh
/home/app # rake db:test
rake aborted!
Sequel::DatabaseConnectionError: Mysql2::Error: Unknown database 'test_sample'
/usr/local/bundle/gems/mysql2-0.5.5/lib/mysql2/client.rb:97:in `connect'
...
/home/schematic/tasks/shared/migrator.rake:9:in `block (2 levels) in <top (required)>'
Tasks: TOP => db:test
(See full trace by running task with --trace)
```

You could create the db and migration table
1. Exit the container
2. Use `make shell.dev.db` to go to the db container
3. Execute scripts for creating DB or creating migration table

```zsh
/home/app # exit
make: *** [Makefile:47: shell.dev] Error 1
ubuntu@my-dev:~/Code/work/scl/repos/test_sample/docker$ make shell.dev
shell.dev     shell.dev.db  
ubuntu@my-dev:~/Code/work/scl/repos/test_sample/docker$ make shell.dev.db
root@ad2b8e8d2444:/home/starrocks# ls
create_initial_database.sh  create_schema_migration_table.sh  mysql.sh
root@ad2b8e8d2444:/home/starrocks# ./create_initial_database.sh 
Execute creation for the first time.
DB test_sample is created.
root@ad2b8e8d2444:/home/starrocks# ./create_schema_migration_table.sh 
Table schema_migrations is created for test_sample.
```

## Database migration create and deploy

### MSSQL & PSQL
After a new project is created, it is most likely to create your database migration before any other development work:

```bash
rake db:create_migration[create_table_CFPAI01]
New migration is created: /home/app/db/migrations/20231116093953_create_table_CFPAI01.rb

rake db:create_migration[create_table_CFPAI02]
New migration is created: /home/app/db/migrations/20231116093959_create_table_CFPAI02.rb

rake db:create_migration[CFPAI02_add_column_created_at]
New migration is created: /home/app/db/migrations/20231116094039_CFPAI02_add_column_created_at.rb

rake db:create_migration[CFPAI01_add_index_VALDAI_PRIDAI]
New migration is created: /home/app/db/migrations/20231116094808_CFPAI01_add_index_VALDAI_PRIDAI.rb

```

**Edit the migration scripts**

Above 2 command created 2 migration script from a template. you may update the mgiration content as what you want.
Edit these file under the path ```<Project-Path>/src/db/migrations/data-staging_acsc``` by ```VScode```.

The below sample is telling you that specify a ```ds``` schema while creating table ```CFPAI``` by using function ```Sequel.qualify```. 

```ruby
Sequel.migration do
  change do
    create_table(Sequel.qualify(:ds, :CFPAI)) do
      String :journalTime, size: 85
      String :sequenceNumber, size: 85
      String :entryType, size: 85
      String :ACCTAI, size: 85
      String :CODEAI, size: 85
      String :CNTIAI, size: 85
      String :CPIDAI, size: 85
      String :PRIDAI, size: 85
      String :VALDAI, size: 85
...

      unique [:sequenceNumber,:entryType]
    end
  end
end
```

## Starrocks migration convention

Since sequel gem does not has starrock adaptation, the migration file would require you to provide raw sql. But for details usage. 

```sh
rake db:create_migration[example_create_table]
New migration is created: /home/app/db/migrations/20240930040354_example_create_table.rb

rake db:create_migration[example_alter_table]
New migration is created: /home/app/db/migrations/20240930040459_example_alter_table_add_column_hi.rb
```

The migration files are then located with path `db/migrations/`

```plaintext
├── Rakefile
├── VERSION
└── db
    └── migrations
        ├── 20240930040354_example_create_table.rb
        └── 20240930040459_example_alter_table_add_column_hi.rb
```

Here's an example table migration script
> This is a template, if you are not familiar with ruby's syntax, don't worry, 
> you could change the block of SQL statements directly to fit your usage, this will work seamlessly, however, 
> commenting with `-- I'm a comment` is not allowed. 

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

### Showing migrations to apply
```
rake db:migrations_to_apply
--> 20240930040354 : example_create_table
--> 20240930040459 : example_alter_table_add_column_hi
```


For more detail information. just check the below 
- Sequel
  https://github.com/jeremyevans/sequel/blob/master/doc/schema_modification.rdoc

- Tiny_tds
  https://rubydoc.info/gems/tiny_tds/0.3.2

- Tiny_tds - data type
  https://github.com/jeremyevans/sequel/blob/master/doc/schema_modification.rdoc#column-types-

**Deploy migration scripts**

- For MSSQL, nun the below command to deploy your migration scripts
  ```bash
  rake db:migrate
  ```
- Run migration for Starrocks use `rake db:reset`
  ```bash
  rake db:reset
  ```
Output: 
```
{:target=>0, :app=>nil}
Completed migration clean of test_sample
{:target=>nil, :app=>nil}
Completed migration up of test_sample
Completed migration reset of test_sample
```
```
StarRocks > describe testing;
+--------------+---------------+------+-------+---------+-------+
| Field        | Type          | Null | Key   | Default | Extra |
+--------------+---------------+------+-------+---------+-------+
| order_id     | bigint        | YES  | true  | NULL    |       |
| order_date   | date          | YES  | true  | NULL    |       |
| customer_id  | int           | YES  | true  | NULL    |       |
| total_amount | decimal(10,2) | YES  | false | NULL    |       |
| hi           | varchar(8)    | YES  | false | NULL    |       |
+--------------+---------------+------+-------+---------+-------+
5 rows in set (0.00 sec)
```

## MSSQL

### Stored Procedures create and deploy
**Create Stored Procedures from template**
```bash
rake sp:create[sp_acsc_CFPAI01_daily_agg]
New Stored procedure template is created: /home/app/stored_procedures/data_staging_acsc/sp_acsc_CFPAI01_daily_agg.sql
```

**Edit the migration scripts**

Above command created stored procedure script from a template. you may update the content as what you want.
Edit these file under the path ```<Project-Path>/src/stored_procedures/data-staging_acsc``` by ```VScode```.

**Deploy Stored procedures**

Run the below command to deploy your Stored procedures, please be noted that the deployment will create the new stored procedures and update the existing stored procedures.
```bash
rake sp:deploy


  >> Executing script from /home/app/stored_procedures/data_staging_acsc/sp_acsc_CFPAI01_daily_agg.sql
/usr/local/bundle/gems/sequel-5.74.0/lib/sequel/adapters/tinytds.rb:34: warning: undefining the allocator of T_DATA class TinyTds::Result
  >> Create new stored procedure.


  >> Executing script from /home/app/stored_procedures/data_staging_acsc/sp_acsc_CFPAI02_daily_agg.sql
  >> Update existing stored procedure.

```
**Notes** the deployment will create New

### SQL Server jobs create and deploy
**Create SQL Server jobs from template**
```bash
rake job:create[acsc_CFPAI01_daily_agg]
New job template is created: /home/app/jobs/data_staging_acsc/acsc_CFPAI01_daily_agg.yaml
New environment template is created: /home/env/jobs/acsc_CFPAI01_daily_agg.env

rake job:create[acsc_CFPAI02_daily_agg]
New job template is created: /home/app/jobs/data_staging_acsc/acsc_CFPAI02_daily_agg.yaml
New environment template is created: /home/env/jobs/acsc_CFPAI02_daily_agg.env
```

**Edit the Job files**

Above command created job yaml and job environment files from  template. you may update the content as what you want.
Edit these file under the path 
- ```<Project-Path>/src/jobs/data-staging_acsc```  
- ```<Project-Path>/docker/deploy/env/jobs``` 
  
  by ```VScode```.

**Deploy Agent Jobs**

Run the below command to deploy your Stored procedures
```bash
rake job:deploy
/usr/local/bundle/gems/sequel-5.74.0/lib/sequel/adapters/tinytds.rb:34: warning: undefining the allocator of T_DATA class TinyTds::Result
  >> Loading configuration from /home/app/jobs/data_staging_acsc/acsc_CFPAI01_daily_agg.yaml
  >> Creating job acsc_CFPAI01_daily_agg
    >> Adding step Transform Step 1
    >> Adding step Transform Step 2
  >> Adding schedule to the job acsc_CFPAI01_daily_agg
  >> Adding server to the job acsc_CFPAI01_daily_agg
---------------------------------------------
  >> Loading configuration from /home/app/jobs/data_staging_acsc/acsc_CFPAI02_daily_agg.yaml
  >> Creating job acsc_CFPAI02_daily_agg
    >> Adding step Transform Step 1
    >> Adding step Transform Step 2
  >> Adding schedule to the job acsc_CFPAI02_daily_agg
  >> Adding server to the job acsc_CFPAI02_daily_agg
---------------------------------------------
```

### Deploy all objects for a single DB target

Run ```rake deploy```  or ```rake deploy[etl_core]```
```bash
/home/app # rake deploy


Deployment started on: dev.db\data_ingestion_cms
--------------------------------------------------------------------------------

Start schema migration to data_ingestion_cms ...
{:target=>nil, :app=>nil}
Completed migration up of data_ingestion_cms

Start Apply views to data_ingestion_cms ...

  >> Executing script from /home/app/views/vw_test1.sql
  >> Update existing view.


Start Apply Stored Procedures to data_ingestion_cms ...

  >> Executing script from /home/app/stored_procedures/sp_test1.sql
  >> Update existing stored procedure.


Deployment completed on: dev.db\data_ingestion_cms
```



### Multi Target Database deployment
**Configuration file for multi database target**
Under the root path in each services, here is a databases.yaml that may define multi databases inside the databases array. here the sample.
```json
---
defaults: &defaults
    DB_TYPE: mssql
    DB_ADAPTER: tinytds

databases:
  - DB_HOST: dev.db
    DB_NAME: data_ingestion_cms_snd
    DATABASE_URL: tinytds://dev.db/data_ingestion_cms_snd?textsize=1024000
    <<: *defaults
  - DB_HOST: dev.db
    DB_NAME: data_ingestion_cms_pla
    DATABASE_URL: tinytds://dev.db/data_ingestion_cms_pla?textsize=1024000
    DB_TYPE: mssql
    DB_ADAPTER: tinytds
```
**Deploy all objects for a Multiple DB target**
execute the ```rake deploy``` ; that will trigger multi database target deployment according to what you defined in ```databases.yaml```. below are the execution output
```bash
/home/app # rake deploy_all[etl_core]


Deployment started on: dev.db\data_ingestion_cms_snd
--------------------------------------------------------------------------------

Start schema migration to data_ingestion_cms_snd ...
{:target=>nil, :app=>"etl_core"}
Completed migration up of data_ingestion_cms_snd

Start Apply views to data_ingestion_cms_snd ...

  >> Executing script from /home/app/views/vw_test1.sql
  >> Update existing view.


Start Apply Stored Procedures to data_ingestion_cms_snd ...

  >> Executing script from /home/app/stored_procedures/sp_test1.sql
  >> Update existing stored procedure.


Deployment completed on: dev.db\data_ingestion_cms_snd



Deployment started on: dev.db\data_ingestion_cms_pla
--------------------------------------------------------------------------------

Start schema migration to data_ingestion_cms_pla ...
{:target=>nil, :app=>"etl_core"}
Completed migration up of data_ingestion_cms_pla

Start Apply views to data_ingestion_cms_pla ...

  >> Executing script from /home/app/views/vw_test1.sql
  >> Update existing view.


Start Apply Stored Procedures to data_ingestion_cms_pla ...

  >> Executing script from /home/app/stored_procedures/sp_test1.sql
  >> Update existing stored procedure.


Deployment completed on: dev.db\data_ingestion_cms_pla

/home/app #
```


### Generate cipher keys
Run ```rake cipher:generate_keys```
```bash
#  rake cipher:generate_keys
Saving private Key (/home/app/.cipher/schematic.priv) ... done
Saving public key (/home/app/.cipher/schematic.pub) ...done
```

### Generate GitOps config
Run ```rake gitops:generate```, then all GitOps config will be generated under /home/app
```bash
/home/app/gitops/
├── base
│   └── cipher-configmap.yaml
└── overlays
    └── dev
        └── configmap
            ├── credentials.yaml
            ├── database.yaml
            └── jobs
                ├── acsc_CFPAI01_daily_agg.yaml
                └── acsc_CFPAI02_daily_agg.yaml
```

## Building/Push applicaiton images
Exit the container, in project folder below VERSION file, ensure the proper version.

```<Project-Path>/src/VERSION```

Run below command to build your application images
```bash
make build.app.rel
```

Run below command to push your application images to repositry
```bash
docker tag quay.io/larryloi/data-staging_acsc:0.1.0-rel.0 quay.io/larryloi/data-staging_acsc:latest
make push.app.rel
```

### Sequel Migration script format conversion
```bash

/home/app # rake sqlsequel:create
Empty file created. (/home/app/.sqlsequel/a.sql)

/home/app # rake sqlsequel:conver
CREATE TABLE [DW_ETL].[Mytest](
        [rid] [bigint] IDENTITY(1,1) NOT NULL,
        [round2_id] [nvarchar](255) NOT NULL,
        [accounting2_date_id] [int] NOT NULL,
        [game2_id] [int] NOT NULL,
        [workstation2] [nvarchar](max) NOT NULL,
        [slip2_id] [int] NOT NULL,
        [amt2] [decimal](10, 4) NOT NULL,
        [jp2_win_amt] [numeric](10, 4) NOT NULL,
        [bet_type2] [char](85) NOT NULL,
        [payout_type2] [char](45) NOT NULL,
        [round2_completed_at] [datetime] NOT NULL,
        [denom2_set_id] [bigint] NOT NULL,
        [member_id2] [varchar](255) NOT NULL,
        [description2] [nvarchar](max) NULL,
        [remark2] [text] NULL,
        [created2_at] [datetime] NOT NULL,
        [updated2_at] [datetime2](7) NOT NULL,
        [acct2_date] [date] NOT NULL,
        [acct2_time] [time] NOT NULL
        [is_settled2] [boolean] NOT NULL,
        [GSP2DR] [varchar] (1) NOT NULL,
        [GSP10_DR] [varchar] (1) NOT NULL,
------------------------------------------------------------

Sequel.migration do
  change do
    create_table(Sequel.qualify(:DW_ETL, :Mytest)) do
      column :rid, 'bigint', auto_increment: true, primary_key: true, null: false
      column :round_id, 'nvarchar', size: 255, null: false
      column :accounting_date_id, Integer, null: false
      column :game_id, Integer, null: false
      column :workstation, 'nvarchar', size: :max, null: false
      column :slip_id, Integer, null: false
      column :amt, 'Decimal', size: [10, 4], null: false
      column :jp_win_amt, 'Numeric', size: [10, 4], null: false
      column :bet_type, String, size: 85, fixed: true, null: false
      column :payout_type, String, size: 45, fixed: true, null: false
      column :round_completed_at, DateTime, null: false
      column :denom_set_id, 'bigint', null: false
      column :member_id, String, size: 255, null: false
      column :description, 'nvarchar', size: :max, null: true
      column :remark, String, text: true, null: true
      column :created_at, DateTime, null: false
      column :updated_at, 'DateTime2(7)', null: false
      column :acct_date, Date, null: false
      column :acct_time, Time, only_time: true, null: false
      column :is_settled, TrueClass, null: false
      column :GSP2DR, String, size: 1, null: false
      column :GSP10_DR, String, size: 1, null: false
    end
  end
end
```

## Project folder structure
Here is the project folder structure for a sample project:

```bash
data-staging_acsc
|-- CHANGELOG.md
|-- README.md
|-- docker
|   |-- Makefile
|   |-- Makefile.env
|   |-- build
|   |   |-- dev
|   |   |   |-- Dockerfile
|   |   |   |-- Makefile
|   |   |   `-- build.env
|   |   |-- rel
|   |   |   |-- Dockerfile
|   |   |   |-- Makefile
|   |   |   `-- build.env
|   |   `-- shared
|   |       |-- build.env
|   |       `-- build.mk
|   |-- deploy
|   |   |-- docker-compose.yaml
|   |   |-- env
|   |   |   |-- cipher.env
|   |   |   |-- database.env
|   |   |   |-- jobs
|   |   |   |   |-- acsc_CFPAI01_daily_agg.env
|   |   |   |   `-- acsc_CFPAI02_daily_agg.env
|   |   |   `-- secret.env
|   |   `-- mssql
|   |       |-- docker-compose.yaml
|   |       `-- scripts
|   |           |-- mssql.sh
|   |           |-- setup-db.sh
|   |           `-- sql
|   |               `-- setup-db.sql
|   `-- make.env
|       |-- base_image.env
|       |-- cipher.env
|       |-- database.env
|       |-- dev_image.env
|       |-- docker.env
|       |-- mssql
|       |   |-- database.env
|       |   `-- secret.env
|       `-- project.env
`-- src
    |-- Rakefile
    |-- VERSION
    |-- db
    |   `-- migrations
    |       |-- 20231116093953_create_table_CFPAI01.rb
    |       |-- 20231116093959_create_table_CFPAI02.rb
    |       |-- 20231116094039_CFPAI02_add_column_created_at.rb
    |       `-- 20231116094808_CFPAI01_add_index_VALDAI_PRIDAI.rb
    |-- gitops
    |   |-- base
    |   |   `-- cipher-configmap.yaml
    |   `-- overlays
    |       `-- dev
    |           `-- configmap
    |               |-- credentials.yaml
    |               |-- database.yaml
    |               `-- jobs
    |                   |-- acsc_CFPAI01_daily_agg.yaml
    |                   `-- acsc_CFPAI02_daily_agg.yaml
    |-- jobs
    |   `-- data_staging_acsc
    |       |-- acsc_CFPAI01_daily_agg.yaml
    |       `-- acsc_CFPAI02_daily_agg.yaml
    `-- stored_procedures
        `-- data_staging_acsc
            |-- sp_acsc_CFPAI01_daily_agg.sql
            `-- sp_acsc_CFPAI02_daily_agg.sql
```