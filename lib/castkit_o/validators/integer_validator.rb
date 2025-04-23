# frozen_string_literal: true

require_relative "numeric_validator"

module Castkit
  module Validators
    # Validator for Integer attributes.
    #
    # Ensures the value is an instance of `Integer` and optionally checks numerical constraints
    # such as `min` and `max`, inherited from `Castkit::Validators::NumericValidator`.
    #
    # @example Validating an Integer attribute
    #   IntegerValidator.call(42, options: { min: 10, max: 100 }, context: :count)
    #
    # @see Castkit::Validators::NumericValidator
    class IntegerValidator < Castkit::Validators::NumericValidator
      # Validates the Integer value.
      #
      # @param value [Object, nil] the value to validate
      # @param options [Hash] validation options (e.g., `min`, `max`)
      # @param context [Symbol, String] the attribute name or context for error messages
      # @raise [Castkit::AttributeError] if the value is not an Integer or fails validation rules
      # @return [void]
      def call(value, options:, context:)
        return type_error!(:integer, value, context: context) unless value.is_a?(::Integer)

        super
      end
    end
  end
end
