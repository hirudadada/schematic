#!/bin/bash

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

db_name=${DB_NAME}

SQL_STMT=$(cat << END_SQL
USE \`${db_name}\`;

CREATE TABLE IF NOT EXISTS routine_load_migrations (
  id BIGINT,
  version VARCHAR(14),
  name VARCHAR(255),
  table_name VARCHAR(255),
  routine_name VARCHAR(255),
  operation VARCHAR(50),
  applied_at DATETIME
)
ENGINE=olap
PRIMARY KEY (id)
DISTRIBUTED BY HASH(id)
PROPERTIES (
  "replication_num" = "1"
);
END_SQL
)

mysql -P 9030 -h ${db_host} -u root -e "$SQL_STMT"

echo "Routine load migration table is created." 