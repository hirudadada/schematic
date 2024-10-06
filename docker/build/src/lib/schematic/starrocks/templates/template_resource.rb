# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class TemplateResource
        attr_reader :name, :type

        def initialize(name, type)
          @name = name
          @type = type
        end

        def create
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end
