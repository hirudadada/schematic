#!/bin/bash

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

db_deploy_user=${DB_DEPLOY_USER}
db_deploy_password=${DB_DEPLOY_PASSWORD}

# if db_deploy_user is equal to root, do not run the SQL_STMT
if [ "$db_deploy_user" == 'root' ]; then
  exit 0
fi

SQL_STMT=$(cat << END_SQL
CREATE USER '${db_deploy_user}'@'%'IDENTIFIED WITH mysql_native_password BY '${db_deploy_password}'
END_SQL
)

mysql -P 9030 -h ${db_host} -u root -e "$SQL_STMT"
