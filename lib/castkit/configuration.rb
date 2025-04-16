# frozen_string_literal: true

require_relative "types"

module Castkit
  # Configuration container for global Castkit settings.
  #
  # This includes type registration, validation, and enforcement flags
  # used throughout Castkit's attribute system.
  class Configuration
    # Default mapping of primitive type definitions.
    #
    # @return [Hash{Symbol => Castkit::Types::Generic}]
    DEFAULT_TYPES = {
      array: Castkit::Types::Collection.new,
      boolean: Castkit::Types::Boolean.new,
      date: Castkit::Types::Date.new,
      datetime: Castkit::Types::DateTime.new,
      float: Castkit::Types::Float.new,
      hash: Castkit::Types::Generic.new,
      integer: Castkit::Types::Integer.new,
      string: Castkit::Types::String.new
    }.freeze

    # Type aliases for primitive type definitions.
    #
    # @return [Hash{Symbol => Symbol}]
    TYPE_ALIASES = {
      collection: :array,
      bool: :boolean,
      int: :integer,
      map: :hash,
      number: :float,
      str: :string,
      timestamp: :datetime,
      uuid: :string
    }.freeze

    # @return [Hash{Symbol => Castkit::Types::Generic}] registered types
    attr_reader :types

    # Whether to raise an error if values should be validated before deserializing, e.g. true -> "true"
    # @return [Boolean]
    attr_accessor :enforce_typing

    # Whether to raise an error if access mode is not recognized.
    # @return [Boolean]
    attr_accessor :enforce_attribute_access

    # Whether to raise an error if a prefix is defined without `unwrapped: true`.
    # @return [Boolean]
    attr_accessor :enforce_unwrapped_prefix

    # Whether to raise an error if an array attribute is missing the `of:` type.
    # @return [Boolean]
    attr_accessor :enforce_array_options

    # Whether to raise an error for unknown and invalid type definitions.
    # @return [Boolean]
    attr_accessor :raise_type_errors

    # Whether to emit warnings when Castkit detects misconfigurations.
    # @return [Boolean]
    attr_accessor :enable_warnings

    # Whether the strict flag is enabled by default for all DataObjects and Contracts.
    # @return [Boolean]
    attr_accessor :strict_by_default

    # Initializes the configuration with default types and enforcement flags.
    #
    # @return [void]
    def initialize
      @types = DEFAULT_TYPES.dup
      @enforce_typing = true
      @enforce_attribute_access = true
      @enforce_unwrapped_prefix = true
      @enforce_array_options = true
      @raise_type_errors = true
      @enable_warnings = true
      @strict_by_default = true

      apply_type_aliases!
    end

    # Registers a new type definition.
    #
    # @param type [Symbol] the symbolic type name (e.g., :uuid)
    # @param klass [Class<Castkit::Types::Generic>] the class to register
    # @param override [Boolean] whether to allow overwriting existing registration
    # @raise [Castkit::TypeError] if the type class is invalid or not a subclass of Generic
    # @return [void]
    def register_type(type, klass, aliases: [], override: false)
      type = type.to_sym
      return if types.key?(type) && !override

      instance = klass.new
      unless instance.is_a?(Castkit::Types::Generic)
        raise Castkit::TypeError, "Expected subclass of Castkit::Types::Generic for `#{type}`"
      end

      types[type] = instance

      Castkit::Core::AttributeTypes.define_type_dsl(type) if Castkit::Core::AttributeTypes.respond_to?(:define_type_dsl)
      return unless aliases.any?

      aliases.each { |alias_type| register_type(alias_type, klass, override: override) }
    end

    # Returns the type handler for a given type symbol.
    #
    # @param type [Symbol]
    # @return [Castkit::Types::Generic]
    # @raise [Castkit::TypeError] if the type is not registered
    def fetch_type(type)
      @types.fetch(type.to_sym) do
        raise Castkit::TypeError, "Unknown type `#{type.inspect}`" if raise_type_errors
      end
    end

    # Returns whether a type is currently registered.
    #
    # @param type [Symbol]
    # @return [Boolean]
    def type_registered?(type)
      @types.key?(type.to_sym)
    end

    # Restores the type registry to its default state.
    #
    # @return [void]
    def reset_types!
      @types = DEFAULT_TYPES.dup
      apply_type_aliases!
    end

    private

    # Registers aliases for primitive type definitions.
    #
    # @return [void]
    def apply_type_aliases!
      TYPE_ALIASES.each do |alias_key, canonical|
        register_type(alias_key, DEFAULT_TYPES[canonical].class)
      end
    end
  end
end
