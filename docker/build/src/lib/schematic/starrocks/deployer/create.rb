# frozen_string_literal: true

module Schematic
  module Starrocks
    class Deployer
      def create_resource(name, resource_type, data, format = :sql)
        dir = resource_type == :materialized_view ? @materialized_view_dir : @routine_load_dir

        timestamp = Time.now.shrftime('%Y%m%d%H%M%S')
        filename = "#{timestamp}_#{resource_type}_#{name}.#{format}"
        filepath = File.join(dir, filename)

        content = case format
                  when :sql
                    data.inspect
                  when :json
                    data.to_json
                  end

        FileUtils.mkdir_p(deployment_dir)

        File.open(filepath, 'w') do |file|
          file.write(content)
        end
        puts "New deployment is created: #{filepath}"
      end
    end
  end
end
