# frozen_string_literal: true

require_relative "base"
require_relative "../validators/boolean_validator"

module Castkit
  module Types
    # Type definition for `:boolean` attributes.
    #
    # Converts strings or numbers into boolean values based on common truthy/falsy indicators.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `boolean :is_active`
    class Boolean < Base
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
        value
      end

      # Serializes the boolean value (pass-through).
      #
      # @param value [Boolean]
      # @return [Boolean]
      def serialize(value)
        value
      end

      # Validates the Boolean value.
      #
      # @param value [Object]
      # @param options [Hash] validation options
      # @param context [Symbol, String] attribute context for error messages
      # @return [void]
      def validate!(value, options: {}, context: {})
        Castkit::Validators::BooleanValidator.call(value, options: options, context: context)
      end
    end
  end
end
