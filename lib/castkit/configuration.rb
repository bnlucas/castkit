# frozen_string_literal: true

require_relative "validators"

module Castkit
  # Configuration container for global Castkit settings.
  #
  # This includes validator registration and enforcement flags for various runtime checks.
  class Configuration
    # Default mapping of primitive types to validators.
    #
    # @return [Hash<Symbol, Class>]
    DEFAULT_VALIDATORS = {
      string: Castkit::Validators::StringValidator,
      integer: Castkit::Validators::NumericValidator,
      float: Castkit::Validators::NumericValidator
    }.freeze

    # @return [Hash<Symbol, #call>] registered validators by type
    attr_reader :validators

    # Whether to raise an error if `of:` is missing for array types.
    # @return [Boolean]
    attr_accessor :enforce_array_of_type

    # Whether to raise an error for unrecognized primitive types.
    # @return [Boolean]
    attr_accessor :enforce_known_primitive_type

    # Whether to raise an error on invalid boolean coercion.
    # @return [Boolean]
    attr_accessor :enforce_boolean_casting

    # Whether to raise an error if a union type has no matching candidate.
    # @return [Boolean]
    attr_accessor :enforce_union_match

    # Whether to raise an error if access mode is not recognized.
    # @return [Boolean]
    attr_accessor :enforce_attribute_access

    # Whether to raise an error if a prefix is defined without `unwrapped: true`.
    # @return [Boolean]
    attr_accessor :enforce_unwrapped_prefix

    # Whether to raise an error if an array attribute is missing the `of:` type.
    # @return [Boolean]
    attr_accessor :enforce_array_options

    # Whether to generating warnings or not, defaults to `true`.
    # @return [Boolean]
    attr_accessor :enable_warnings

    # Initializes the configuration with default validators and enforcement settings.
    #
    # @return [void]
    def initialize
      @validators = DEFAULT_VALIDATORS.dup
      @enforce_array_of_type = true
      @enforce_known_primitive_type = true
      @enforce_boolean_casting = true
      @enforce_union_match = true
      @enforce_attribute_access = true
      @enforce_unwrapped_prefix = true
      @enforce_array_options = true
      @enable_warnings = true
    end

    # Registers a custom validator for a given type.
    #
    # @param type [Symbol] the type symbol (e.g., :string, :integer)
    # @param validator [#call] a callable object that implements `call(value, options:, context:)`
    # @param override [Boolean] whether to override an existing validator
    # @raise [Castkit::Error] if validator does not respond to `.call`
    # @return [void]
    def register_validator(type, validator, override: false)
      return if @validators.key?(type.to_sym) && !override

      unless validator.respond_to?(:call)
        raise Castkit::Error, "Validator for `#{type}` must respond to `.call(value, options:, context:)`"
      end

      @validators[type.to_sym] = validator
    end

    # Returns the registered validator for the given type.
    #
    # @param type [Symbol]
    # @return [#call, nil]
    def validator_for(type)
      validators[type.to_sym]
    end

    # Resets all validators to their default mappings.
    #
    # @return [void]
    def reset_validators!
      @validators = DEFAULT_VALIDATORS.dup
    end
  end
end
