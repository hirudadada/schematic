# frozen_string_literal: true

namespace :mssql do
  namespace :gitops do
    desc "Generate GitOps config for MSSQL"
    task :generate do
      generator = Schematic::Mssql::Generator::GitOps.new
      generator.generate
      puts "Generated GitOps config for MSSQL"
    end
  end
end 