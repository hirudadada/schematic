# frozen_string_literal: true

module Schematic
  class Template
    def self.render(template, context)
      ERB.new(template).result_with_hash(context)
    end
  end
end
