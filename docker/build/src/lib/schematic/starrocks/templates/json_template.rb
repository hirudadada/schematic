# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class JsonTemplate < TemplateResource
        def initialize(name)
          super(name, :json)
        end

        def create
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end

