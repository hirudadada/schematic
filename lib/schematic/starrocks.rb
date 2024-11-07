# frozen_string_literal: true

require_relative 'starrocks/version'
require_relative 'starrocks/types'
require_relative 'starrocks/templates'
require_relative 'starrocks/providers'
require_relative 'starrocks/deployables'
require_relative 'starrocks/deployer'
require_relative 'starrocks/generator'

module Schematic
  module Starrocks
    class Error < StandardError; end
  end
end 