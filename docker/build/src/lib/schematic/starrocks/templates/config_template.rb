# frozen_string_literal: true

module Schematic
  module Starrocks
    module Templates
      class ConfigTemplate < TemplateResource
        def initialize(name, task)
          super(name, task, :config)
        end

        def create
          raise NotImplementedError, "abstract class #{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end

