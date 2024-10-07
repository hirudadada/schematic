# frozen_string_literal: true

require 'inflecto'

module Schematic
  module Starrocks
    module Templates
      class RbTemplate < TemplateResource
        def initialize(name, task)
          super(name, task, :rb)
        end

        def create
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end

        protected

        def sanitize(input)
          input.gsub(/\W/, ' ').strip.tr(' ', '_')
        end

        def camelize_and_sanitize(input)
          sanitized_input = sanitize(input)

          # Camelized the sanitized input
          camelized_input = Inflecto.camelize(sanitized_input)

          camelized_input
        end
      end
    end
  end
end

