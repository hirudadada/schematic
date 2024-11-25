# frozen_string_literal: true

module Schematic
  module Starrocks
    class Error < StandardError; end
    class ConnectionError < Error
      attr_reader :retries
      def initialize(message, retries)
        @retries = retries
        super(message)
      end
    end
    class StateTransformationError < Error
      attr_reader :current_state, :desired_state
      def initialize(current_state, desired_state, message)
        @current_state = current_state
        @desired_state = desired_state
        super(message)
      end
    end
    class RoutineLoadError < Error; end
    class ValidationError < Error; end
  end
end