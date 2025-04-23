# frozen_string_literal: true

require_relative "base"
require_relative "../validators/collection_validator"

module Castkit
  module Types
    # Type definition for `:array` attributes.
    #
    # Wraps any value in an array using `Array(value)` coercion. This ensures consistent array representation
    # even if the input is a single value or nil.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `array :tags, of: :string`
    class Collection < Base
      # Deserializes the value into an array using `Array(value)`.
      #
      # @param value [Object]
      # @return [::Array]
      def deserialize(value)
        Array(value)
      end

      # Validates the Array value.
      #
      # @param value [Object]
      # @param options [Hash] validation options
      # @param context [Symbol, String, nil] attribute context for error messages
      # @return [void]
      def validate!(value, options: {}, context: nil)
        Castkit::Validators::CollectionValidator.call(value, options: options, context: context)
      end
    end
  end
end
