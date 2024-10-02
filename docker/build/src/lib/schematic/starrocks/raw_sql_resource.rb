# frozen_string_literal: true

class RawSqlResource
  attr_reader :name, :sql

  def initialize(name, sql)
    @name = name
    @sql = sql
  end
end

class ConfigResource
  attr_reader :name, :config

  def initialize(name, config)
    @name = name
    @config = config
  end

  def sql
  end

  protected

  def generate_sql_from_config
  end
end

