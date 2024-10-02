#!/bin/bash

db_host="127.0.0.1"

if [ -n "$DB_HOST" ]; then
    db_host="$DB_HOST"
fi

mysql -P 9030 -h ${db_host} -u root --prompt="StarRocks > "
