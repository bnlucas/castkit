# frozen_string_literal: true

require_relative "generic"
require_relative "../validators/numeric_validator"

module Castkit
  module Types
    # Type definition for `:integer` attributes.
    #
    # Handles deserialization from raw input (e.g., strings, floats) to Integer,
    # applies optional numeric validation rules (e.g., `min`, `max`), and returns
    # the value unchanged during serialization.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `integer :count`
    class Integer < Generic
      # Deserializes the input value to an Integer.
      #
      # @param value [Object]
      # @return [Integer]
      def deserialize(value)
        value.to_i
      end

      # Serializes the Integer value.
      #
      # @param value [Integer]
      # @return [Integer]
      def serialize(value)
        value
      end

      # Validates the Integer value using Castkit's NumericValidator.
      #
      # Supports options like `min:` and `max:`.
      #
      # @param value [Object]
      # @param options [Hash] validation options
      # @param context [Symbol, String] attribute context for error messages
      # @return [void]
      def validate!(value, options: {}, context: {})
        Castkit::Validators::NumericValidator.call(value, options: options, context: context)
      end
    end
  end
end
