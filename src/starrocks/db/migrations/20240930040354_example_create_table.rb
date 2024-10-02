# frozen_string_literal: true

Sequel.migration do
  up do
    execute(<<~SQL)
      -- CREATE TABLE testing (
      --     order_id BIGINT,
      --     order_date DATE, 
      --     customer_id INT,
      --     total_amount DECIMAL(10,2)
      -- )
      -- ENGINE=olap
      -- PRIMARY KEY (order_id, order_date, customer_id)
      -- PARTITION BY RANGE (order_date)
      -- (
      --     PARTITION p201901 VALUES LESS THAN ('2019-02-01'),
      --     PARTITION p201902 VALUES LESS THAN ('2019-03-01')
      -- )
      -- DISTRIBUTED BY HASH(order_id, order_date, customer_id)
      -- ORDER BY (order_date, customer_id);
    SQL
  end

  down do
    execute(<<~SQL)
      -- DROP TABLE IF EXISTS testing;
    SQL
  end
end
