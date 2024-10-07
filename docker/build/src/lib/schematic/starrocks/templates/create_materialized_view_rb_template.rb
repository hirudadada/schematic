# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class CreateMaterializedViewRbTemplate < RbTemplate
        def initialize(view_name)
          super(view_name, :create_materialized_view)
        end

        def create
          <<~RUBY
            # frozen_string_literal: true

            {
              name: \'#{sanitize(name)}\', # this is the view name, required
              task: :#{task}, # required
              sql: (<<~SQL)
                SELECT
                  o.order_id,
                  o.order_date,
                  o.customer_id,
                  o.total_amount,
                  e.event_type,
                  e.event_details
                FROM
                    orders o
                LEFT JOIN
                    events e
                ON
                    o.customer_id = e.user_id
                WHERE
                    e.event_time > '2019-02-01'
              SQL
            }
          RUBY
        end
      end
    end
  end
end
