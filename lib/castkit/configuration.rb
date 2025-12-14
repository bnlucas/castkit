# frozen_string_literal: true

require_relative "types"
require "cattri"

module Castkit
  # Configuration container for global Castkit settings.
  #
  # This includes type registration, validation, and enforcement flags
  # used throughout Castkit's attribute system.
  class Configuration
    include Cattri

    # Default mapping of primitive type definitions.
    #
    # @return [Hash{Symbol => Castkit::Types::Base}]
    DEFAULT_TYPES = {
      array: Castkit::Types::Collection.new,
      boolean: Castkit::Types::Boolean.new,
      date: Castkit::Types::Date.new,
      datetime: Castkit::Types::DateTime.new,
      float: Castkit::Types::Float.new,
      hash: Castkit::Types::Base.new,
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

    cattri :types, -> { DEFAULT_TYPES.dup }, expose: :read_write
    cattri :default_plugins, [], expose: :read_write
    cattri :enforce_typing, true, expose: :read_write
    cattri :enforce_attribute_access, true, expose: :read_write
    cattri :enforce_unwrapped_prefix, true, expose: :read_write
    cattri :enforce_array_options, true, expose: :read_write
    cattri :raise_type_errors, true, expose: :read_write
    cattri :enable_warnings, true, expose: :read_write
    cattri :strict_by_default, true, expose: :read_write

    # Initializes the configuration with default types and enforcement flags.
    #
    # @return [void]
    def initialize
      super
      self.types = DEFAULT_TYPES.dup
      self.enforce_typing = true
      self.enforce_attribute_access = true
      self.enforce_unwrapped_prefix = true
      self.enforce_array_options = true
      self.raise_type_errors = true
      self.enable_warnings = true
      self.strict_by_default = true
      self.default_plugins = []

      apply_type_aliases!
    end

    # Registers a new type definition.
    #
    # @param type [Symbol] the symbolic type name (e.g., :uuid)
    # @param klass [Class<Castkit::Types::Base>] the class to register
    # @param override [Boolean] whether to allow overwriting existing registration
    # @raise [Castkit::TypeError] if the type class is invalid or not a subclass of Castkit::Types::Base
    # @return [void]
    def register_type(type, klass, aliases: [], override: false)
      type = type.to_sym
      return if types.key?(type) && !override

      instance = klass.new
      unless instance.is_a?(Castkit::Types::Base)
        raise Castkit::TypeError, "Expected subclass of Castkit::Types::Base for `#{type}`"
      end

      types[type] = instance

      Castkit::Core::AttributeTypes.define_type_dsl(type) if Castkit::Core::AttributeTypes.respond_to?(:define_type_dsl)
      return unless aliases.any?

      aliases.each { |alias_type| register_type(alias_type, klass, override: override) }
    end

    # Register a custom plugin for use with Castkit::DataObject.
    #
    # @example Loading as a default plugin
    #   Castkit.configure do |config|
    #     config.register_plugin(:custom, CustomPlugin)
    #     config.default_plugins [:custom]
    #   end
    #
    # @example Loading it directly in a Castkit::DataObject
    #   class UserDto < Castkit::DataObject
    #     enable_plugins :custom
    #   end
    def register_plugin(name, plugin)
      Castkit::Plugins.register(name, plugin)
    end

    # Returns the type handler for a given type symbol.
    #
    # @param type [Symbol]
    # @return [Castkit::Types::Base]
    # @raise [Castkit::TypeError] if the type is not registered
    def fetch_type(type)
      types.fetch(type.to_sym) do
        raise Castkit::TypeError, "Unknown type `#{type.inspect}`" if raise_type_errors
      end
    end

    # Returns whether a type is currently registered.
    #
    # @param type [Symbol]
    # @return [Boolean]
    def type_registered?(type)
      types.key?(type.to_sym)
    end

    # Restores the type registry to its default state.
    #
    # @return [void]
    def reset_types!
      self.types = DEFAULT_TYPES.dup
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
