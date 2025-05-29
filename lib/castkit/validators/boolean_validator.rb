# frozen_string_literal: true

require_relative "base"

module Castkit
  module Validators
    # Validator for boolean attributes.
    #
    # Accepts various representations of boolean values, including strings and integers.
    # Converts common truthy/falsy string values into booleans, otherwise raises a type error.
    #
    # This validator is typically used internally by `Castkit::Types::Boolean`.
    #
    # @example
    #   validator = Castkit::Validators::BooleanValidator.new
    #   validator.call("true", _options: {}, context: :enabled) # => true
    #   validator.call("0", _options: {}, context: :enabled)    # => false
    #   validator.call("nope", _options: {}, context: :enabled) # raises Castkit::AttributeError
    class BooleanValidator < Castkit::Validators::Base
      # Validates the Boolean value.
      #
      # @param value [Object] the input to validate
      # @param _options [Hash] unused, provided for consistency with other validators
      # @param context [Symbol, String] the attribute name or path for error messages
      # @return [Boolean]
      # @raise [Castkit::AttributeError] if the value is not a recognizable boolean
      def call(value, _options:, context:)
        case value.to_s.downcase
        when "true", "1"
          true
        when "false", "0"
          false
        else
          type_error!(:boolean, value, context: context)
        end
      end
    end
  end
end
