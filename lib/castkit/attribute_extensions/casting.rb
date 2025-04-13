# frozen_string_literal: true

require "date"
require_relative "../data_object"
require_relative "error_handling"

module Castkit
  module AttributeExtensions
    # Provides typecasting logic for attributes based on their declared type.
    #
    # Supports primitive types, arrays, nested Castkit::DataObject types, and union types.
    module Casting
      include Castkit::AttributeExtensions::ErrorHandling

      PRIMITIVE_CASTERS = {
        integer: lambda(&:to_i),
        float: lambda(&:to_f),
        string: lambda(&:to_s),
        hash: ->(v) { v },
        array: ->(v) { Array(v) }
      }.freeze

      private

      # Casts a value based on the attribute's declared type.
      #
      # @param value [Object] the input value to cast
      # @return [Object, nil] the cast value
      # @raise [Castkit::AttributeError] if the value cannot be cast
      def cast(value)
        handle_error(:array_of_type) if type == :array && options[:of].nil?
        value = default if value.nil?
        return if value.nil? && optional?

        cast_value(value)
      end

      # Delegates casting logic based on the attribute's type.
      #
      # This method is invoked internally by `#cast` after nil handling and default fallback.
      #
      # - For union types (`Array` of types), attempts each in order.
      # - For array types, maps over elements with `#cast_element`.
      # - For nested data objects, delegates to `.cast`.
      # - For primitive types, uses `#cast_primitive`.
      #
      # @param value [Object] the raw input value to cast
      # @return [Object, nil] the cast value
      # @raise [Castkit::AttributeError] if casting fails for all union types or invalid primitives
      def cast_value(value)
        if type.is_a?(Array)
          try_union_cast(value)
        elsif type == :array
          Array(value).map { |v| cast_element(v) }
        elsif dataobject?
          type.cast(value)
        else
          cast_primitive(value)
        end
      end

      # Attempts to cast the value against a union of possible types.
      #
      # @param value [Object]
      # @return [Object] the first successful cast result
      # @raise [Castkit::AttributeError] if no types match
      def try_union_cast(value)
        last_error = nil

        type.each do |t|
          return try_cast_type(value, t)
        rescue Castkit::AttributeError => e
          last_error = e
        end

        raise last_error || handle_error(:union, types: type)
      end

      # Tries to cast a value to a specific type.
      #
      # @param value [Object]
      # @param type [Symbol, Class] the type to try
      # @return [Object, nil]
      def try_cast_type(value, type)
        return type.cast(value) if Castkit.dataobject?(type)

        cast_primitive(value, type: type)
      end

      # Casts an element of an array attribute.
      #
      # @param value [Object]
      # @return [Object, nil]
      def cast_element(value)
        if Castkit.dataobject?(options[:of])
          options[:of].cast(value)
        else
          validate_element_type!(value)
          cast_primitive(value, type: options[:of])
        end
      end

      # Casts a primitive value based on its type.
      #
      # @param value [Object]
      # @param type [Symbol]
      # @return [Object, nil]
      # @raise [Castkit::AttributeError]
      def cast_primitive(value, type: self.type)
        return cast_boolean(value) if type == :boolean
        return Date.parse(value.to_s) if type == :date
        return DateTime.parse(value.to_s) if type == :datetime

        PRIMITIVE_CASTERS.fetch(type) do
          handle_error(:primitive, type: type)
        end.call(value)
      end

      # Casts a value to boolean.
      #
      # @param value [Object]
      # @return [Boolean, nil]
      # @raise [Castkit::AttributeError]
      def cast_boolean(value)
        case value.to_s.downcase
        when "true", "1"
          true
        when "false", "0"
          false
        else
          handle_error(:boolean, value: value)
        end
      end

      # Validates element type for arrays, if `enforce_array_of_type` is enabled.
      #
      # @param value [Object]
      # @return [void]
      def validate_element_type!(value)
        return unless Castkit.configuration.enforce_array_of_type

        validator = Castkit.configuration.validator_for(options[:of])
        validator.call(value, options: options, context: "#{field}[]")
      end
    end
  end
end
