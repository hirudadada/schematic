# frozen_string_literal: true

require_relative 'starrocks/types'
require_relative 'starrocks/defaults'
require_relative 'starrocks/utils'
require_relative 'starrocks/providers'
require_relative 'starrocks/deployables'
require_relative 'starrocks/templates'
require_relative 'starrocks/generator'
require_relative 'starrocks/deployer'
require_relative 'starrocks/template_manager'

module Schematic
  module Starrocks
    class DeploymentError < StandardError; end
    class AnalyzingError < DeploymentError; end
  end
end
