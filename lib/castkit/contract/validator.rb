# frozen_string_literal: true

require_relative "../error"

module Castkit
  module Contract
    # Responsible for validating input against a set of Castkit::Attribute definitions.
    #
    # The validator supports:
    # - Primitive type validation
    # - Nested Castkit::DataObject validation
    # - Collections of DataObjects
    # - Strict or relaxed key handling
    #
    # Returns a hash of errors if validation fails, keyed by attribute name.
    class Validator
      class << self
        # Validates input against the provided attribute definitions.
        #
        # @param attributes [Array<Castkit::Attribute>] the attributes to validate
        # @param input [Hash] the raw input data
        # @param options [Hash] validator options:
        #   - strict: whether unknown keys should raise
        #   - allow_unknown: whether unknown keys are permitted
        #   - warn_on_unknown: whether to log warnings for unknown keys
        #
        # @return [Hash{Symbol => String, Hash, nil}] validation errors per attribute
        def call(attributes, input, **options)
          new(attributes, **options).call(input)
        end

        def call!(attributes, input, **options)
          errors = call(attributes, input, **options)
          raise Castkit::ContractError.new("Validation failed", errors: errors) if errors.any?
        end
      end

      # Executes validation against the input data.
      #
      # @param input [Hash] the incoming data to validate
      # @return [Hash{Symbol => String, Hash}] validation errors, empty if valid
      def call(input)
        validate_access_config!
        errors = {}

        @attributes.each do |attribute|
          value = resolve_input_value(input, attribute)
          error = validate_attribute(attribute, value)

          errors[attribute.field] = error if error
        end

        validate_unknown_attributes!(input, errors)
        errors
      end

      private

      # @param attributes [Array<Castkit::Attribute>] attributes to validate
      # @param options [Hash] validation options
      def initialize(attributes, **options)
        @attributes = attributes
        @options = options
      end

      # Validates a single attribute value.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object]
      # @return [String, Hash, nil] error message, nested error hash, or nil if valid
      def validate_attribute(attribute, value)
        return nil if value.nil? && attribute.optional?
        return "#{attribute.field} is required" if value.nil? && attribute.required?

        if attribute.dataobject?
          validate_nested_dataobject(attribute, value)
        elsif attribute.type == :array
          validate_nested_array(attribute, value)
        else
          validate_primitives(attribute, value)
        end
      end

      # Validates a nested DataObject instance.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Castkit::DataObject]
      # @return [Hash, nil] validation errors or nil
      def validate_nested_dataobject(attribute, value)
        return nil unless value.respond_to?(:to_h)

        validate_nested(attribute, value, attribute.type)
      end

      # Validates a collection of nested DataObject instances.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Array<Castkit::DataObject | Symbol>]
      # @return [Hash{Integer => Hash}, String, nil] indexed validation errors or message
      def validate_nested_array(attribute, value)
        return "must be an array" unless value.is_a?(Array)

        errors = {}

        value.each_with_index do |item, index|
          error = validate_nested(attribute, item, attribute.options[:of], context: "#{attribute.field}[#{index}]")
          errors[index] = error if error
        end

        errors.empty? ? nil : errors
      end

      # Helper method used to validate nested types for Castkit::DataObject and array types.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object] the data to validate against
      # @param type [Castkit::DataObject, Symbol]
      def validate_nested(attribute, value, type, context: nil)
        return validate_primitive_type(attribute, value, type, context: context) unless Castkit.dataobject?(type)

        errors = Castkit::Contract::Validator.call(
          type.attributes.values,
          value.to_h,
          **dataobject_options(type)
        )

        errors.empty? ? nil : errors
      end

      # Validates a primitive value against a union of allowed types.
      #
      # Attempts each type in order until one successfully casts and validates.
      # If all types fail, the last error message is returned.
      #
      # @param attribute [Castkit::Attribute] the attribute definition
      # @param value [Object] the value to validate
      # @return [String, nil] the validation error message, or nil if valid
      def validate_primitives(attribute, value)
        last_error = nil

        Array(attribute.type).each do |type|
          last_error = validate_primitive_type(attribute, value, type)
          return nil if last_error.nil?
        end

        last_error || "could not match attribute type(s): #{attribute.type.inspect}"
      end

      # Validates a primitive value against a specific type.
      #
      # @param attribute [Castkit::Attribute] the attribute definition
      # @param value [Object] the value to validate
      # @param type [Symbol, Class] the specific type to attempt validation with
      # @return [String, nil] the error message if validation fails, otherwise nil
      def validate_primitive_type(attribute, value, type, context: nil)
        context ||= attribute.field

        Castkit.type_caster(type).call(
          value,
          validator: attribute.options[:validator],
          options: attribute.options,
          context: context
        )

        nil
      rescue Castkit::AttributeError => e
        e.message
      end

      # Validates unknown attributes based on strict/allow config.
      #
      # @param input [Hash]
      # @param errors [Hash]
      # @return [void]
      def validate_unknown_attributes!(input, errors)
        return if @options[:allow_unknown]

        unknown_keys = unknown_attributes(input)
        unknown_keys.each { |key| errors[key] = "#{key} is not allowed" } if @options[:strict]

        handle_unknown_keys!(unknown_keys) unless unknown_keys.empty?
      end

      # Resolves the value for a given attribute from the input hash.
      #
      # @param input [Hash]
      # @param attribute [Castkit::Attribute]
      # @return [Object, nil]
      def resolve_input_value(input, attribute)
        attribute.key_path(with_aliases: true).each do |path|
          value = path.reduce(input) do |memo, key|
            next memo unless memo.is_a?(Hash)

            memo.key?(key) ? memo[key] : memo[key.to_s]
          end
          return value unless value.nil?
        end

        nil
      end

      # Collects all keys present in the input hash that don't have attribute definitions.
      #
      # @param input [Hash]
      # @return [Array<Symbol>]
      def unknown_attributes(input)
        valid_keys = @attributes.flat_map { |attr| [attr.key] + attr.options[:aliases] }.map(&:to_sym).uniq
        input.keys.map(&:to_sym) - valid_keys
      end

      # Warns if both `strict` and `allow_unknown` are enabled.
      #
      # @return [void]
      def validate_access_config!
        return unless @options[:strict] && @options[:allow_unknown]

        Castkit.warning "⚠️ [Castkit] Both `strict` and `allow_unknown` are enabled, which can lead to " \
                        "conflicting behavior. `strict` is being disabled to respect `allow_unknown`."
      end

      # Raises or warns on unknown input keys based on config.
      #
      # @param unknown_keys [Array<Symbol>]
      # @return [void]
      def handle_unknown_keys!(unknown_keys)
        raise Castkit::ContractError, "Unknown attribute(s): #{unknown_keys.join(", ")}" if strict?
        return unless @options[:warn_on_unknown]

        Castkit.warning "⚠️  [Castkit] Unknown attribute(s) ignored: #{unknown_keys.join(", ")}"
      end

      # Returns nested validation options from a DataObject class.
      #
      # @param obj [Castkit::DataObject]
      # @return [Hash]
      def dataobject_options(obj)
        {
          strict: obj.strict,
          allow_unknown: obj.allow_unknown,
          warn_on_unknown: obj.warn_on_unknown
        }
      end

      # Whether strict validation mode is enabled (unless allow_unknown overrides).
      #
      # @return [Boolean]
      def strict?
        @options[:allow_unknown] ? false : !!@options[:strict]
      end
    end
  end
end
