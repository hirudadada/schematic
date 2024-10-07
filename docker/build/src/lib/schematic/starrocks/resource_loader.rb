# # frozen_string_literal: true
#
# module Schematic
#   module Starrocks
#     class ResourceLoader
#       def initialize(resources_dirs = '')
#         @resources_dirs = resources_dirs
#       end
#
#       def load_raw_sql_resources
#         resources = []
#         @resource_dirs.each do |dir|
#           Dir.glob(File.join(dir, '*.sql')).each do |path|
#             name = File.basename(path, '.sql')
#             sql = File.read(path)
#             resources << RawSQLResource.new(name, sql)
#           end
#         end
#         resources
#       end
#
#       def load_template_resources
#         resources = []
#         @resource_dirs.each do |dir|
#           Dir.glob(File.join(dir, '*.json')).sort.each do |path|
#             config = JSON.parse(File.read(path))
#             task = config['task']
#             name = config['name']
#             values = config['values']
#
#             case task
#             when ':create_routine_load'
#               path = template_path('routine_load')
#               template = File.read(path)
#               sql = TemplateEngine.render(template, values)
#               resources << RoutineLoadResource.new(name, sql)
#             when ':create_materialized_view'
#               path = template_path('materialized_view')
#               template = File.read(path)
#               sql = TemplateEngine.render(template, values)
#               resources << MaterializedViewResource.new(name, sql)
#             end
#           end
#         end
#         resources
#       end
#
#       private
#
#       def template_path(template_name)
#         File.join('templates', "#{template_name}.sql.erb")
#       end
#
#       # def initialize(deployer)
#       #   @deployer = deployer
#       # end
#       # def add_config_resource(name, config)
#       #   @resources << ConfigResource.new(name, config)
#       # end
#       #
#       # def add_raw_sql_resource(name, sql)
#       #   @resources << RawSqlResource.new(name, sql)
#       # end
#       #
#       # def deploy_all
#       #   @resources.each do |resource|
#       #     resource.deploy(@deployer)
#       #   end
#       # end
#     end
#   end
# end
