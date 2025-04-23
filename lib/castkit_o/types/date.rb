# frozen_string_literal: true

require "date"
require_relative "base"

module Castkit
  module Types
    # Type definition for `:date` attributes.
    #
    # Handles deserialization from strings and other input into `Date` objects,
    # and serializes `Date` values into ISO8601 strings.
    #
    # This class is used internally by Castkit when an attribute is defined with:
    #   `date :published_on`
    class Date < Base
      # Deserializes the input value to a `Date` instance.
      #
      # @param value [Object]
      # @return [::Date]
      # @raise [ArgumentError] if parsing fails
      def deserialize(value)
        ::Date.parse(value.to_s)
      end

      # Serializes a `Date` object to ISO8601 string format.
      #
      # @param value [::Date]
      # @return [String]
      def serialize(value)
        value.iso8601
      end
    end
  end
end
