# frozen_string_literal: true

require "date"
require_relative "base"

module Castkit
  module Types
    # Type definition for `:datetime` attributes.
    #
    # Handles deserialization from strings and other input into `DateTime` objects,
    # and serializes `DateTime` values into ISO8601 strings.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `datetime :published_ad`
    class DateTime < Base
      # Deserializes the input value to a `DateTime` instance.
      #
      # @param value [Object]
      # @return [::DateTime]
      # @raise [ArgumentError] if parsing fails
      def deserialize(value)
        ::DateTime.parse(value.to_s)
      end

      # Serializes a `DateTime` object to ISO8601 string format.
      #
      # @param value [::DateTime]
      # @return [String]
      def serialize(value)
        value.iso8601
      end
    end
  end
end
