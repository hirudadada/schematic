# frozen_string_literal: true

module Schematic
  module Starrocks
    module Utils
      module FilePath
        def self.ensure_dir(dir)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        end
      end
    end
  end
end
