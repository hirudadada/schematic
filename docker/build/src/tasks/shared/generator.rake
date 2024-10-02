# frozen-string-literal: true

require_relative '../../lib/schematic/generator'

namespace :gitops do
  desc "Generate GitOps config"
  task :generate do
    Schematic::Generator::GitOpsConfig.new.generate
  end
end
