# frozen_string_literal: true

module Castkit
  module Validators
    # Abstract base class for all attribute validators.
    #
    # Validators ensure that a value conforms to specific rules (e.g., type, format, range).
    # Subclasses must implement the instance method `#call`.
    #
    # @abstract
    class BaseValidator
      class << self
        # Invokes the validator with the given arguments.
        #
        # @param value [Object] the attribute value to validate
        # @param options [Hash] the attribute options (e.g., `min`, `max`, `format`)
        # @param context [Symbol, String, Hash] the attribute name or context for error reporting
        # @return [void]
        # @raise [Castkit::AttributeError] if validation fails
        def call(value, options:, context:)
          new.call(value, options: options, context: context)
        end
      end

      # Validates the attribute value.
      #
      # @abstract Override in subclasses.
      #
      # @param value [Object] the attribute value to validate
      # @param options [Hash] the attribute options
      # @param context [Symbol, String, Hash] the attribute name or context
      # @return [void]
      # @raise [NotImplementedError] unless implemented in a subclass
      def call(value, options:, context:)
        raise NotImplementedError, "#{self.class.name} must implement `#call`"
      end
    end
  end
end
