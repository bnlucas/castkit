# frozen_string_literal: true

require_relative "../validators/base"

module Castkit
  module Validators
    # Validator for array (collection) attributes.
    #
    # Ensures that the provided value is an instance of `Array`. This validator is
    # typically used by `Castkit::Types::Collection` for attributes defined as arrays.
    #
    # @example
    #   validator = Castkit::Validators::CollectionValidator.new
    #   validator.call([1, 2, 3], _options: {}, context: :tags) # => passes
    #   validator.call("foo", _options: {}, context: :tags)     # raises Castkit::AttributeError
    class CollectionValidator < Castkit::Validators::Base
      # Validates that the value is an Array.
      #
      # @param value [Object] the value to validate
      # @param options [Hash] unused, for interface consistency
      # @param context [Symbol, String] the field or context for error messaging
      # @return [void]
      # @raise [Castkit::AttributeError] if value is not an Array
      def call(value, options:, context:) # rubocop:disable Lint/UnusedMethodArgument
        type_error!(:array, value, context: context) unless value.is_a?(::Array)
      end
    end
  end
end
