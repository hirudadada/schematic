#!/bin/bash

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

db_name=${DB_NAME}

SQL_STMT=$(cat << END_SQL
USE \`${db_name}\`;

CREATE TABLE IF NOT EXISTS schema_migrations (
  filename VARCHAR(255) NOT NULL
)
ENGINE=olap
PRIMARY KEY (filename);
END_SQL
)

mysql -P 9030 -h ${db_host} -u root -e "$SQL_STMT"

echo "Schema migration table is created."
