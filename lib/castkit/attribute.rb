# frozen_string_literal: true

require_relative "error"
require_relative "data_object"
require_relative "attribute_extensions/options"
require_relative "attribute_extensions/casting"
require_relative "attribute_extensions/access"
require_relative "attribute_extensions/validation"
require_relative "attribute_extensions/serialization"

module Castkit
  # Represents a typed attribute on a Castkit::DataObject.
  #
  # Provides casting, validation, access control, and serialization behavior.
  class Attribute
    include Castkit::AttributeExtensions::Options
    include Castkit::AttributeExtensions::Casting
    include Castkit::AttributeExtensions::Access
    include Castkit::AttributeExtensions::Validation
    include Castkit::AttributeExtensions::Serialization

    # @return [Symbol] the attribute name
    attr_reader :field

    # @return [Symbol, Class, Array] the declared type (normalized)
    attr_reader :type

    # @return [Hash] attribute options (including aliases, default, access, etc.)
    attr_reader :options

    # Initializes a new attribute definition.
    #
    # @param field [Symbol] the name of the attribute
    # @param type [Symbol, Class, Array] the type or array of types
    # @param default [Object, Proc] optional default value
    # @param options [Hash] additional configuration options
    def initialize(field, type, default: nil, **options)
      @field = field
      @type = normalize_type(type)
      @default = default
      @options = populate_options(options)

      validate!
    end

    # Returns a hash representation of the attribute definition.
    #
    # @return [Hash]
    def to_hash
      {
        field: field,
        type: type,
        options: options,
        default: default
      }
    end

    # @see #to_hash
    alias to_h to_hash

    private

    # Populates default values and normalizes internal options.
    #
    # @param options [Hash]
    # @return [Hash]
    def populate_options(options)
      options = DEFAULT_OPTIONS.merge(options)
      options[:aliases] = Array(options[:aliases] || [])
      options[:of] = normalize_type(options[:of]) if options[:of]

      options
    end

    # Normalizes a declared type to a symbol or class reference.
    #
    # @param type [Symbol, Class, Array]
    # @return [Symbol, Class, Array]
    # @raise [Castkit::AttributeError] if the type is not valid
    def normalize_type(type)
      return type.map { |t| normalize_type(t) } if type.is_a?(Array)
      return type if type.is_a?(Class) && type < Castkit::DataObject

      case type
      when Class
        return :boolean if [TrueClass, FalseClass].include?(type)

        type.name.downcase.to_sym
      when Symbol
        type
      else
        raise_error!("Unknown type: #{type.inspect}")
      end
    end

    # Validates the final value against a validator if required.
    #
    # @param value [Object]
    # @param context [Symbol, String]
    # @return [void]
    def validate_value!(value, context:)
      return if value.nil? && optional?
      return if type.is_a?(Array) || dataobject?

      validator = options[:validator] || Castkit.configuration.validator_for(type)
      validator&.call(value, options: options, context: context)
    end

    # Raises a Castkit::AttributeError with optional context.
    #
    # @param message [String]
    # @param context [Hash, nil]
    # @raise [Castkit::AttributeError]
    def raise_error!(message, context: nil)
      raise Castkit::AttributeError.new(message, context: context || to_h)
    end
  end
end
