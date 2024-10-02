require_relative '../lib/schematic/sqlsequel'

namespace :sqlsequel do
  desc "Create source SQL format a.sql for conversion to sequel migration format "
  task :create do |_, args|
    Schematic::Sqlsequel.new.create
  end

  desc "Conver a.sql from SQL format to sequel migration format"
  task :conver do |_, args|
    Schematic::Sqlsequel.new.conver
  end
end