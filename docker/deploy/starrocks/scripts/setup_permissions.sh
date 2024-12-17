#!/bin/bash

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

db_deploy_user=${DB_DEPLOY_USER}

# if db_deploy_user is equal to root, do not run the SQL_STMT
if [ "$db_deploy_user" == 'root' ]; then
  exit 0
fi

# removed unecessary permission since this is community starrocks
# CREATE MASKING POLICY, CREATE ROW ACCESS POLICY, CREATE PIPE
SQL_STMT=$(cat <<END_SQL
GRANT DELETE, DROP, INSERT, SELECT, ALTER, EXPORT, UPDATE ON ALL TABLES IN ALL DATABASES TO '${db_deploy_user}';
GRANT CREATE TABLE, DROP, ALTER, CREATE VIEW, CREATE FUNCTION, CREATE MATERIALIZED VIEW ON ALL DATABASES TO '${db_deploy_user}';
GRANT ALL ON ALL CATALOGS TO '${db_deploy_user}';
GRANT ALL ON ALL MATERIALIZED VIEWS IN ALL DATABASES TO '${db_deploy_user}';
GRANT ALL ON ALL VIEWS IN ALL DATABASES TO '${db_deploy_user}';
GRANT CREATE EXTERNAL CATALOG, REPOSITORY,FILE ON SYSTEM TO '${db_deploy_user}';
GRANT SELECT ON ALL TABLES IN ALL DATABASES TO '${db_deploy_user}';
END_SQL
)

mysql -P 9030 -h ${db_host} -u root -e "$SQL_STMT"
