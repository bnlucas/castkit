# frozen_string_literal: true

module Castkit
  class AttributeTypeMissing < Error; end
  class AttributeTypeMismatch < Error; end
  class InvalidAttributeType < Error
    def initialize(type:)
      super("Invalid attribute type: #{type}")
    end
  end
end
