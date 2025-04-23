# frozen_string_literal: true

require_relative "base"
require_relative "../validators/float_validator"

module Castkit
  module Types
    # Type definition for `:integer` attributes.
    #
    # Handles deserialization from raw input (e.g., strings, floats) to Float,
    # applies optional numeric validation rules (e.g., `min`, `max`), and returns
    # the value unchanged during serialization.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `integer :count`
    class Float < Base
      # Deserializes the input value to an Float.
      #
      # @param value [Object]
      # @return [Float]
      def deserialize(value)
        value.to_f
      end

      # Serializes the Float value.
      #
      # @param value [Float]
      # @return [Float]
      def serialize(value)
        value
      end

      # Validates the Float value using Castkit's FloatValidator.
      #
      # Supports options like `min:` and `max:`.
      #
      # @param value [Object]
      # @param options [Hash] validation options
      # @param context [Symbol, String] attribute context for error messages
      # @return [void]
      def validate!(value, options: {}, context: {})
        Castkit::Validators::FloatValidator.call(value, options: options, context: context)
      end
    end
  end
end
