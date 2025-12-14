# frozen_string_literal: true

require_relative "castkit"
require_relative "error"
require_relative "attributes/options"
require_relative "dsl/attribute"

module Castkit
  # Represents a typed attribute on a `Castkit::DataObject`.
  #
  # This class is responsible for:
  # - Type normalization (symbol, class, or data object)
  # - Default and option resolution
  # - Validation hooks
  # - Access and serialization control
  #
  # Attributes are created automatically when using the DSL in `DataObject`, but
  # can also be created manually or through reusable definitions.
  #
  # @see Castkit::Attributes::Definition
  # @see Castkit::DSL::Attribute::Options
  # @see Castkit::DSL::Attribute::Access
  # @see Castkit::DSL::Attribute::Validation
  class Attribute
    include Castkit::DSL::Attribute
    include Cattri

    cattri :field, nil, expose: :read, final: true
    cattri :type, nil, expose: :read, final: true
    cattri :options, nil, expose: :read, final: true

    class << self
      # Defines a reusable attribute definition via a DSL wrapper.
      #
      # @param type [Symbol, Class] The base type to define.
      # @param options [Hash] Additional attribute options.
      # @yield The block to configure options or transformations.
      # @return [Array<(Symbol, Hash)>] a tuple of the final type and options hash
      def define(type, **options, &block)
        normalized_type = normalize_type(type)
        Castkit::Attributes::Definition.define(normalized_type, **options, &block)
      end

      # Normalizes a declared type (symbol, class, or array) for internal usage.
      #
      # @param type [Symbol, Class, Array] the input type
      # @return [Symbol, Class<Castkit::DataObject>] the normalized form
      def normalize_type(type)
        return type.map { |t| normalize_type(t) } if type.is_a?(Array)
        return type if Castkit.dataobject?(type)

        process_type(type).to_sym
      end

      # Converts a raw type into a normalized symbol.
      #
      # Recognized forms:
      # - `TrueClass`/`FalseClass` → `:boolean`
      # - Class → `class.name.downcase.to_sym`
      # - Symbol → passed through
      #
      # @param type [Symbol, Class] the type to convert
      # @return [Symbol] normalized type symbol
      # @raise [Castkit::AttributeError] if the type is invalid
      def process_type(type)
        case type
        when Class
          return :boolean if [TrueClass, FalseClass].include?(type)

          type.name.downcase.to_sym
        when Symbol
          type
        else
          raise Castkit::AttributeError, "Unknown type: #{type.inspect}"
        end
      end
    end

    # Initializes a new attribute definition.
    #
    # @param field [Symbol] the attribute name
    # @param type [Symbol, Class, Array<Symbol, Class>] the type (or list of types)
    # @param default [Object, Proc, nil] optional static or callable default
    # @param options [Hash] additional attribute options
    def initialize(field, type, default: nil, **options)
      super()

      cattri_variable_set(:field, field, final: true)
      cattri_variable_set(:type, self.class.normalize_type(type), final: true)

      @default = default
      cattri_variable_set(:options, populate_options(options), final: true)

      validate!
    end

    # Converts the attribute definition to a serializable hash.
    #
    # @return [Hash] the full attribute metadata
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

    # Populates default values and prepares internal options.
    #
    # @param options [Hash] the user-provided options
    # @return [Hash] the merged and normalized options
    def populate_options(options)
      options = Castkit::Attributes::Options::DEFAULTS.merge(options)
      options[:aliases] = Array(options[:aliases] || [])
      options[:of] = self.class.normalize_type(options[:of]) if options[:of]

      options
    end

    # Raises a standardized attribute error with context.
    #
    # @param message [String] the error message
    # @param context [Hash, nil] optional override for context payload
    # @raise [Castkit::AttributeError]
    def raise_error!(message, context: nil)
      raise Castkit::AttributeError.new(message, context: context || to_h)
    end
  end
end
