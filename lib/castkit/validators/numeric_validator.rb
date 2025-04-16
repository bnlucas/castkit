# frozen_string_literal: true

require_relative "base_validator"

module Castkit
  module Validators
    # Validates that a numeric value falls within the allowed range.
    #
    # Supports `:min` and `:max` options to enforce bounds.
    class NumericValidator < Castkit::Validators::BaseValidator
      # Validates the numeric value.
      #
      # @param value [Numeric] the value to validate
      # @param options [Hash] validation options (e.g., `min`, `max`)
      # @param context [Symbol, String] the attribute name or key for error messages
      # @raise [Castkit::AttributeError] if the value violates min/max bounds
      # @return [void]
      def call(value, options:, context:)
        if options[:min] && value < options[:min]
          raise Castkit::AttributeError, "#{context} must be >= #{options[:min]}"
        end

        return unless options[:max] && value > options[:max]

        raise Castkit::AttributeError, "#{context} must be <= #{options[:max]}"
      end
    end
  end
end
