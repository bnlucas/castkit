# frozen_string_literal: true

module Castkit
  module Validators
    # Abstract base class for all attribute validators.
    #
    # Validators are responsible for enforcing value constraints (e.g., type checks,
    # format rules, numerical bounds). All validators must inherit from this base class
    # and implement the `#call` instance method.
    #
    # Supports both instance-level and class-level invocation via `.call`.
    #
    # @abstract Subclasses must implement `#call`.
    class Base
      class << self
        # Entry point for validating a value using the validator class.
        #
        # Instantiates the validator and invokes `#call` with the provided arguments.
        #
        # @param value [Object] the value to validate
        # @param options [Hash] additional validation options (e.g., `min`, `max`, `format`)
        # @param context [Symbol, String, Hash] context for the validation (usually the attribute name)
        # @return [void]
        # @raise [Castkit::AttributeError] if validation fails and `raise_type_errors` is true
        def call(value, options:, context:)
          new.call(value, options: options, context: context)
        end
      end

      # Validates the value.
      #
      # @abstract
      # @param value [Object] the value to validate
      # @param options [Hash] validation options (e.g., min, max, format)
      # @param context [Symbol, String, Hash] context for validation errors
      # @return [void]
      # @raise [NotImplementedError] if not implemented in subclass
      def call(value, options:, context:)
        raise NotImplementedError, "#{self.class.name} must implement `#call`"
      end

      protected

      # Emits or raises a type error depending on global configuration.
      #
      # @param type [Symbol] the expected type (e.g., `:integer`)
      # @param value [Object, nil] the received value
      # @param context [Symbol, String, nil] context to include in error messages
      # @raise [Castkit::AttributeError] if `raise_type_errors` is enabled
      # @return [void]
      def type_error!(type, value, context: nil)
        message = "#{context || "value"} must be a #{type}, got #{value}"
        raise Castkit::AttributeError, message if Castkit.configuration.raise_type_errors

        Castkit.warning "[Castkit] #{message}" if Castkit.configuration.enable_warnings
      end
    end
  end
end
