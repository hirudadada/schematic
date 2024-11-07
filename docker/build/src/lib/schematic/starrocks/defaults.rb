# frozen_string_literal: true

module Schematic
  module Starrocks
    module Defaults
      DEFAULT_COLUMNS = %w[uid column1 column2 column3].freeze
      DEFAULT_JSONPATHS = %w[$.uid $.column1 $.column2 $.column3].freeze

      # Properties that can be altered according to official doc
      ALTERABLE_PROPERTIES = %i[
        desired_concurrent_number
        max_error_number
        max_batch_interval
        max_batch_rows
        max_batch_size
        jsonpaths
        json_root
        strip_outer_array
        strict_mode
        timezone
      ].freeze

      # Default properties for both create and alter
      DEFAULT_PROPERTIES = {
        desired_concurrent_number: '3',
        format: 'json',
        max_error_number: '0',
        max_filter_ratio: '1.0',
        max_batch_interval: '10',
        max_batch_rows: '2000000',
        task_consume_second: '15',
        task_timeout_second: '60',
        max_batch_size: '2000000',
        jsonpaths: DEFAULT_JSONPATHS
      }.freeze

      def init_properties =
        DEFAULT_PROPERTIES.merge(
          desired_concurrent_number: ENV.fetch('ROUTINE_LOAD_CONCURRENT_NUMBER', DEFAULT_PROPERTIES[:desired_concurrent_number]),
          format: ENV.fetch('ROUTINE_LOAD_FORMAT', DEFAULT_PROPERTIES[:format]),
          max_error_number: ENV.fetch('ROUTINE_LOAD_MAX_ERROR_NUMBER', DEFAULT_PROPERTIES[:max_error_number]),
          max_filter_ratio: ENV.fetch('ROUTINE_LOAD_MAX_FILTER_RATIO', DEFAULT_PROPERTIES[:max_filter_ratio]),
          max_batch_interval: ENV.fetch('ROUTINE_LOAD_MAX_BATCH_INTERVAL', DEFAULT_PROPERTIES[:max_batch_interval]),
          max_batch_rows: ENV.fetch('ROUTINE_LOAD_MAX_BATCH_ROWS', DEFAULT_PROPERTIES[:max_batch_rows]),
          task_consume_second: ENV.fetch('ROUTINE_LOAD_TASK_CONSUME_SECOND', DEFAULT_PROPERTIES[:task_consume_second]),
          task_timeout_second: ENV.fetch('ROUTINE_LOAD_TASK_TIMEOUT_SECOND', DEFAULT_PROPERTIES[:task_timeout_second])
        )
    end
  end
end 
