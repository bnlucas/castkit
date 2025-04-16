# frozen_string_literal: true

require_relative "generic"

module Castkit
  module Types
    # Type definition for `:boolean` attributes.
    #
    # Converts strings or numbers into boolean values based on common truthy/falsy indicators.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `boolean :is_active`
    class Boolean < Generic
      # Deserializes the input into a boolean value.
      #
      # Accepts:
      # - `"true"`, `"1"` (case-insensitive) → `true`
      # - `"false"`, `"0"` (case-insensitive) → `false`
      #
      # @param value [Object]
      # @return [Boolean]
      # @raise [Castkit::TypeError] if the value cannot be coerced to a boolean
      def deserialize(value)
        case value.to_s.downcase
        when "true", "1"
          true
        when "false", "0"
          false
        else
          type_error!(:boolean, value)
        end
      end

      # Serializes the boolean value (pass-through).
      #
      # @param value [Boolean]
      # @return [Boolean]
      def serialize(value)
        value
      end
    end
  end
end
