# frozen_string_literal: true

require_relative "numeric_validator"

module Castkit
  module Validators
    # Validator for Float attributes.
    #
    # Ensures the value is a `Float`, and applies any numeric bounds (`min`, `max`)
    # defined in the attribute options. Inherits shared logic from `NumericValidator`.
    #
    # @example
    #   validator = Castkit::Validators::FloatValidator.new
    #   validator.call(3.14, options: { min: 0.0 }, context: :price) # => passes
    #   validator.call(42, options: {}, context: :price)             # raises Castkit::AttributeError
    class FloatValidator < Castkit::Validators::NumericValidator
      # Validates that the value is a Float and within optional bounds.
      #
      # @param value [Object, nil] the value to validate
      # @param options [Hash] validation options (e.g., `min`, `max`)
      # @param context [Symbol, String] the attribute name or key for error messages
      # @raise [Castkit::AttributeError] if value is not a Float or out of range
      # @return [void]
      def call(value, options:, context:)
        return type_error!(:float, value, context: context) unless value.is_a?(::Float)

        super
      end
    end
  end
end
