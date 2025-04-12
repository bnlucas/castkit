# frozen_string_literal: true

module Castkit
  module AttributeExtensions
    # Handles serialization (`dump`) and deserialization (`load`) of attribute values.
    #
    # Supports primitive types, arrays, and nested Castkit::DataObject instances.
    module Serialization
      # Serializes a value into a format suitable for output (e.g., JSON or Hash).
      #
      # If the value is a Castkit::DataObject, a custom serializer is used if configured.
      #
      # @param value [Object] the value to serialize
      # @param visited [Set, nil] used for circular reference detection
      # @return [Object] the serialized value
      def dump(value, visited: nil)
        return value if value.nil?

        if type == :array
          Array(value).map { |val| dump_element(val, visited: visited) }
        else
          dump_element(value, visited: visited)
        end
      end

      # Deserializes and validates a value during object instantiation.
      #
      # Applies default value, casts, and runs validators.
      #
      # @param value [Object] the input value
      # @param context [Symbol] the attribute name or context key
      # @return [Object] the deserialized and validated value
      # @raise [Castkit::AttributeError] if value is required but missing
      def load(value, context:)
        value = default if value.nil?
        return raise_error!("#{field} is required for instantiation") if value.nil? && required?

        value = cast(value)
        validate_value!(value, context: context)

        value
      end

      private

      # Serializes a single element value.
      #
      # - Uses a serializer if the value is a Castkit::DataObject.
      # - Converts `to_h` if the value is hash-like.
      #
      # @param value [Object] the element to dump
      # @param visited [Set, nil]
      # @return [Object]
      def dump_element(value, visited: nil)
        return value if value.nil? || primitive?(value)

        if value.is_a?(Castkit::DataObject)
          serializer = options[:serializer] || value.class.serializer || Castkit::DefaultSerializer
          serializer.call(value, visited: visited)
        elsif hashable?(value)
          value.to_h(visited)
        else
          value
        end
      end

      # Checks whether a value is a hashable object suitable for `to_h` dumping.
      #
      # @param value [Object]
      # @return [Boolean]
      def hashable?(value)
        value.respond_to?(:to_h) && !primitive?(value) && !value.is_a?(Castkit::Attribute)
      end

      # Determines if a value is a primitive type.
      #
      # @param value [Object]
      # @return [Boolean]
      def primitive?(value)
        case value
        when String, Symbol, Numeric, TrueClass, FalseClass, NilClass, Hash, Array
          true
        else
          false
        end
      end
    end
  end
end
