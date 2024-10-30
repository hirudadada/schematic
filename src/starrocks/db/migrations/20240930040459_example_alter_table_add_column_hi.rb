# frozen_string_literal: true

Sequel.migration do
  up do
    execute(<<~SQL)
      ALTER TABLE example_table add column `hi` varchar(8) NULL COMMENT "hi";
    SQL
  end

  down do
    execute(<<~SQL)
      ALTER TABLE example_table drop column `hi`;
    SQL
  end
end
