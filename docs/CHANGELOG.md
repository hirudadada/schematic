## [0.9.1] (2024-12-06)

* Changed syntax for

## [0.8.5] (2024-11-07)

* Refactored database setup initialization
  - Separated schema_migrations and routine_load_migrations table creation
  - Made routine_load_migrations table creation on-demand
  - Improved initialization flow in Migrator and Deployer
  - Better separation of concerns in setup modules
* Enhanced StarRocks support
  - Moved routine load table creation to migration strategy
  - Improved table creation timing
  - Better resource initialization control
* Added StarRocks 3.2.10 compatibility
  - Updated table creation syntax for StarRocks 3.2.10
  - Modified schema_migrations and routine_load_migrations table definitions
  - Added DISTRIBUTED BY HASH clause for table creation
  - Standardized PRIMARY KEY definitions
* Fixed database setup modules
  - Consolidated table creation syntax across setup files
  - Removed duplicate PRIMARY KEY definitions
  - Updated StarRocks table creation in Database::Setup
  - Improved table creation consistency
* Enhanced database initialization
  - Added database-type specific setup handling in Migrator
  - Improved StarRocks setup in Deployer
  - Added proper routine load migrations table initialization
  - Better separation of database-specific setup logic
* Added StarRocks Routine Load feature
  - Added migration-style deployment system for Routine Load
  - Added type checking with dry-types
  - Added support for sensitive data hydration
  - Added GitOps configmap generation
  - Added cluster configuration management
  - Added deployment strategies (Migration/AutoStop/UserDefined)
  - Added migration tracking in database
* Updated documentation
  - Added detailed deployment flow documentation
  - Updated project structure guide
  - Added database setup information
* Updated documentation for Routine Load feature
* Fixed StarRocks table creation syntax
* Added proper error handling for deployments
* Added support for StarRocks
* Implemented Makefile handlers for StarRocks project creation
* Added Docker Compose setup for StarRocks development environment
* Refactored folder structure to accommodate StarRocks adaptation
* Added scripts to handle waiting for StarRocks FE and BE to be up during local development
* Added Rake tasks for creating and deploying StarRocks migrations
* Added a `psql` and `starrocks` folder under `project.tmpl` for storing PostgreSQL and StarRocks src's rake tasks, respectively.
<!-- * Added Rake task for creating StarRocks Routine Load configurations -->
* Updated guides and README
	1. Added instructions for setting up a StarRocks project.
	2. Updated the instructions for setting the database password based on the database type (MSSQL, PostgreSQL, or StarRocks).
	3. Mentioned that the `secret.env` file for StarRocks is located under `docker/make.env/starrocks/secret.env`.


## [0.2.5] (2023-11-05)

	* Properly handled when image is not found when checking image info via make command
	* Enhanced the way to load job environment settings in development
	* Added environment variable for schematic version in base image
	* Added environment variable for app version in dev image
	* Added basic tasks for loading environment settings and showing version
	* Used DEV_IMAGE in docker compose for project template
	* Added a rake task to test database connection
	* Used hyphen instead of underscore in project path
	* Fixed naming convention for deploy job image
	* Fixed naming convention for base image
	* Added a rake task to show app and Schematic version info
	* Exposed default ports for MS SQL and PostgreSQL for development
	* Changed default migration dir not to contain db name
	* Properly set values for environment variables, SCHEMATIC_HOME, ENV_HOME and APP_HOME and work directory in docker image
	* Added GitOpsConfig generator and related rake tasks

## [0.2.0] (2023-10-26)

	* Fixed a gitignore rule to allow some secret env files to be checked into code repository
	* Refactored make env files to consolidate configuration settings
	* Added environment variables DB_TYPE to indicate database engine: mssql or psql so that database identifier mangling can be properly configured in Ruby Sequel
	* Provided convenient Makefile targets to show related docker images
	* Updated README.md for project creation with proper database passwords configured

## [0.1.5] (2023-10-24)

	* Refactored global configurations and build/deploy/make configurations
	* Refactored database configurations
	* Refactored folder structure
	* Refined project template generation

## [0.1.0] (2023-10-20)

	* Initial commit for the project
