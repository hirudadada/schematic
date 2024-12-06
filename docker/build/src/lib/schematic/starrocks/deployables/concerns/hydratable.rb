module Schematic
  module Starrocks
    module Deployables
      module Concerns
        module Hydratable
          def hydrate_placeholders(data)
            raise NotImplementedError
          end

          def hydrate_enabled?
            options[:hydrate] != false
          end

          protected

          def execute_with_hydration(client, data)
            hydrated_data = if hydrate_enabled?
              hydrate_placeholders(data)
            else
              data
            end

            execute_deploy(client, hydrated_data)
          end
        end
      end
    end
  end
end