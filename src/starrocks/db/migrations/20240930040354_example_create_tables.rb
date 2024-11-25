# frozen_string_literal: true

Sequel.migration do
  up do
    (1..30).each do |i|
      execute(<<~SQL)
        CREATE TABLE example_table_#{i} (
          id BIGINT,
          created_at DATETIME,
          name VARCHAR(255) NOT NULL,
          description VARCHAR(255),
          value INT,
          updated_at DATETIME,
          #{case i % 3
          when 0
            "category VARCHAR(255),\n          price DECIMAL(10,2)"
          when 1
            "active BOOLEAN,\n          status VARCHAR(255)"
          when 2
            "quantity INT,\n          location VARCHAR(255)"
          end}
        )
        ENGINE=olap
        PRIMARY KEY (id, created_at)
        PARTITION BY RANGE(created_at) (
          PARTITION p_future VALUES LESS THAN (MAXVALUE)
        )
        DISTRIBUTED BY HASH(id)
        PROPERTIES (
          "replication_num" = "1",
          "in_memory" = "false",
          "storage_format" = "DEFAULT"
        );
      SQL
    end
  end

  down do
    (1..30).each do |i|
      execute(<<~SQL)
        DROP TABLE IF EXISTS example_table_#{i};
      SQL
    end
  end
end 