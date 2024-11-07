# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class TemplateResource
        attr_reader :name, :type, :provider

        def initialize(name, type, provider = nil)
          @name = name
          @type = type
        end

        def create
          raise NotImplementedError, "#{self.class} must implement 'create' method"
        end
      end
    end
  end
end
