# frozen_string_literal: true

module Castkit
  module Types
    # Abstract base class for type definitions in Castkit.
    #
    # Provides default behavior for (de)serialization, validation, and coercion.
    # All primitive types should subclass this and override methods as needed.
    #
    # The `cast!` method is the primary entry point used by attribute processing
    # to validate and coerce values in a predictable order.
    class Base
      class << self
        # Coerces and validates a value for use in a Castkit DataObject.
        #
        # When `force_type` is true, the value is deserialized (coerced) first,
        # then validated. This is useful when a value may need to be converted
        # before it can pass validation (e.g. `"123"` → `123`).
        #
        # Otherwise, the raw value is validated before coercion.
        #
        # @param value [Object] the input value
        # @param validator [#call, nil] optional custom validator (default uses `validate!`)
        # @param options [Hash] options passed to `validate!`, e.g., `min`, `max`, `force_type`
        # @param context [Symbol, String, nil] context label for error messages
        # @return [Object] the deserialized and validated value
        def cast!(value, validator: nil, options: {}, context: {}, **extra_options)
          options = options.merge(extra_options)
          instance = new
          validator ||= options.delete(:validator)
          validator ||= default_validator(instance)

          if options[:force_type]
            deserialized_value = instance.deserialize(value)
            invoke_validator(validator, deserialized_value, options: options, context: context)
            return deserialized_value
          end

          invoke_validator(validator, value, options: options, context: context)
          instance.deserialize(value)
        end

        # Deserializes the value using the default type behavior.
        #
        # @param value [Object]
        # @return [Object] the coerced value
        def deserialize(value)
          new.deserialize(value)
        end

        # Serializes the value using the default type behavior.
        #
        # @param value [Object]
        # @return [Object]
        def serialize(value)
          new.serialize(value)
        end

        # Validates the value using the default validator.
        #
        # @param value [Object] the value to check
        # @param options [Hash] validation rules (e.g., min, max, format)
        # @param context [Symbol, String] label for error reporting
        # @return [void]
        def validate!(value, options: {}, context: {})
          new.validate!(value, options: options, context: context)
        end

        private

        # Builds a default validator from the instance itself.
        #
        # @param instance [Castkit::Types::Base]
        # @return [Proc] a lambda wrapping `#validate!`
        def default_validator(instance)
          lambda do |value, options: {}, context: nil|
            instance.validate!(value, options: options, context: context)
          end
        end

        # Dispatches validation to support callable validators with different arities.
        #
        # @param validator [#call, Proc] the validator to invoke
        # @param value [Object] the value being validated
        # @param options [Hash] validation options
        # @param context [Symbol, String, nil] context for error messages
        # @return [void]
        def invoke_validator(validator, value, options:, context:)
          return validator.call(value, options: options, context: context) unless validator.is_a?(Proc)

          case validator.arity
          when 1
            validator.call(value)
          when 2
            validator.call(value, options)
          else
            validator.call(value, options: options, context: context)
          end
        end
      end

      # Deserializes the value. Override in subclasses to coerce input (e.g., `"123"` → `123`).
      #
      # @param value [Object]
      # @return [Object]
      def deserialize(value)
        value
      end

      # Serializes the value. Override in subclasses if the output should be transformed.
      #
      # @param value [Object]
      # @return [Object]
      def serialize(value)
        value
      end

      # Validates the value. No-op by default.
      #
      # @param value [Object]
      # @param options [Hash]
      # @param context [Symbol, String]
      # @return [void]
      def validate!(value, options: {}, context: {})
        # override in subclasses
      end

      protected

      # Emits or raises a type error depending on configuration.
      #
      # @param type [Symbol]
      # @param value [Object, nil]
      # @return [void]
      def type_error!(type, value, context: nil)
        message = "#{context || "value"} must be a #{type}, got #{value}"
        raise Castkit::AttributeError, message if Castkit.configuration.raise_type_errors

        Castkit.warning "[Castkit] #{message}" if Castkit.configuration.enable_warnings
      end
    end
  end
end
