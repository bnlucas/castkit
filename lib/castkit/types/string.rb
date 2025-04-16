# frozen_string_literal: true

require_relative "generic"
require_relative "../validators/string_validator"

module Castkit
  module Types
    # Type definition for `:string` attributes.
    #
    # Coerces any input to a string using `to_s`, and validates that the resulting value is a `String`.
    # Supports optional format validation via a `:format` option (Regexp or Proc).
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `string :id`
    class String < Generic
      # Deserializes the value by coercing it to a string using `to_s`.
      #
      # @param value [Object]
      # @return [String]
      def deserialize(value)
        value.to_s
      end

      # Serializes the value as-is.
      #
      # @param value [String]
      # @return [String]
      def serialize(value)
        value
      end

      # Validates the value is a `String` and optionally matches a format.
      #
      # @param value [Object]
      # @param options [Hash] validation options (e.g., `format: /regex/`)
      # @param context [Symbol, String]
      # @raise [Castkit::AttributeError] if validation fails
      # @return [void]
      def validate!(value, options: {}, context: {})
        Castkit::Validators::StringValidator.call(value, options: options, context: context)
      end
    end
  end
end
