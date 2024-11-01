# frozen-string-literal: true

require_relative '../../lib/schematic/starrocks/generator'

namespace :gitops do
  namespace :starrocks do
    desc "Generate Starrocks GitOps config"
    task :generate do
      Schematic::Starrocks::Generator::RoutineLoadConfigMap.new.generate
    end
  end
end
