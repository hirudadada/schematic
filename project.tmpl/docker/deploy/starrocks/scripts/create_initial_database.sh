#!/bin/bash

max_retries=10
retries=0
success=false

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

db_name=${DB_NAME}

SQL_STMT=$(cat << END_SQL
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
USE \`${db_name}\`;
END_SQL
)

until $success || [ $retries -eq $max_retries ]; do

  echo "Execute creation for the first time."

  mysql -P 9030 -h ${db_host} -u root -e "$SQL_STMT"

  exit_status=$?

  if [ $exit_status -eq 0 ]; then
    echo "DB ${db_name} is created."
    success=true
  else
    echo "Failed to create database ${db_name}. Retrying..."
    echo "Waiting for db to up..."
    sleep 20

    retries=$((retries+1))
  fi
done

if ! $success; then
  echo "Maximum retries reached. Failed to create database ${db_name}."
  exit 1
fi
