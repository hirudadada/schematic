# frozen_string_literal: true

module Schematic
  module Starrocks
    module Deployables
      class HydratableRoutineLoadConfigDeployable < RoutineLoadConfigDeployable
        include Concerns::Hydratable

        def deploy(client)
          execute_with_hydration(client, data)
        end

        protected

        def execute_deploy(client, hydrated_data)
          provider = options[:provider] || Providers::RoutineLoadConfigProvider.create
          
          client.transaction do
            client.run("USE #{provider.db_name};")
            
            load_info = extract_load_info(hydrated_data)
            strategy = @strategy || Strategies.create(options)
            strategy.execute(client, [build_sql(hydrated_data)], load_info)
          end
        end

        def hydrate_placeholders(data)
          # 實現 YAML 配置的變數替換邏輯
          Types::RoutineLoadConfig[data]
        end

        private

        def build_sql(data)
          case data[:operation].to_sym
          when :create
            create_routine_load_sql(data)
          when :alter
            alter_routine_load_sql(data)
          else
            Types::StrictString["#{data[:operation].to_s.upcase} ROUTINE LOAD FOR `#{data[:routine_name]}`;"]
          end
        end
      end
    end
  end
end 
