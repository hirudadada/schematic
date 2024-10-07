# frozen_string_literal: true

module Schematic
  module Starrocks
    module Utils
      module FilePath
        module_function

        def generate_filepath(dir, task, name, format, timestamp = Time.now.strftime('%Y%m%d%H%M%S'))
          filename = "#{timestamp}-#{task}-#{name}.#{format}"
          File.join(dir, filename)
        end

        def extract_name_and_task(filepath)
          basename = File.basename(filepath, File.extname(filepath))
          parts = basename.split('-')

          task = parts[1] # Assuming the name is the second part after timestamp
          name = parts[2] # Assuming the name is the third part after timestamp and task

          [name, task]
        end
      end
    end
  end
end
