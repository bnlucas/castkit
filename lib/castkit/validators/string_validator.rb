# frozen_string_literal: true

require_relative "base_validator"

module Castkit
  module Validators
    # Validates that a value is a String and optionally conforms to a format.
    #
    # Supports format validation using a Regexp or a custom Proc.
    class StringValidator < Castkit::Validators::BaseValidator
      # Validates the string value.
      #
      # @param value [Object] the value to validate
      # @param options [Hash] validation options (e.g., `format: /regex/` or `format: ->(v) { ... }`)
      # @param context [Symbol, String] the attribute name or key for error messages
      # @raise [Castkit::AttributeError] if value is not a string or fails format validation
      # @return [void]
      def call(value, options:, context:)
        raise Castkit::AttributeError, "#{context} must be a string" unless value.is_a?(String)

        return unless options[:format]

        case options[:format]
        when Regexp
          raise Castkit::AttributeError, "#{context} must match format" unless value =~ options[:format]
        when Proc
          raise Castkit::AttributeError, "#{context} failed format validation" unless options[:format].call(value)
        else
          raise Castkit::AttributeError, "#{context} has unsupported format validator: #{options[:format].class}"
        end
      end
    end
  end
end
