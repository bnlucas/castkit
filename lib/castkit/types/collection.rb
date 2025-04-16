# frozen_string_literal: true

require_relative "generic"

module Castkit
  module Types
    # Type definition for `:array` attributes.
    #
    # Wraps any value in an array using `Array(value)` coercion. This ensures consistent array representation
    # even if the input is a single value or nil.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `array :tags, of: :string`
    class Collection < Generic
      # Deserializes the value into an array using `Array(value)`.
      #
      # @param value [Object]
      # @return [::Array]
      def deserialize(value)
        Array(value)
      end
    end
  end
end
