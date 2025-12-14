# frozen_string_literal: true

require "cattri"
require_relative "core/attribute_types"

# Castkit is a lightweight, type-safe data object system for Ruby.
#
# It provides a declarative DSL for defining DTOs with typecasting, validation,
# access control, serialization, deserialization, and OpenAPI-friendly schema generation.
#
# @example Defining a simple data object
#   class UserDto < Castkit::DataObject
#     string :name
#     integer :age, required: false
#   end
#
#   user = UserDto.new(name: "Alice", age: 30)
#   user.to_h #=> { name: "Alice", age: 30 }
#
# @see Castkit::Contract
# @see Castkit::DataObject
module Castkit
  # Namespace used for registering generated DataObjects.
  module DataObjects; end

  # Namespace used for registering generated contracts.
  module Contracts; end

  # Namespace used for registering generated plugins.
  module Plugins; end

  class << self
    # Yields the global configuration object for customization.
    #
    # @example Disabling array enforcement
    #   Castkit.configure do |config|
    #     config.enforce_typing = false
    #   end
    #
    # @yieldparam config [Castkit::Configuration] the mutable config object
    # @return [void]
    def configure
      yield(configuration)
    end

    # Retrieves the global Castkit configuration instance.
    #
    # @return [Castkit::Configuration] the configuration object
    def configuration
      @configuration ||= Configuration.new
    end

    # Emits a warning to STDERR if `enable_warnings` is enabled in config.
    #
    # @param message [String] the warning message
    # @return [void]
    def warning(message)
      warn message if configuration.enable_warnings
    end

    # Checks whether a given object is a subclass of Castkit::DataObject.
    #
    # @param obj [Object] the object to test
    # @return [Boolean] true if obj is a Castkit::DataObject class
    def dataobject?(obj)
      obj.is_a?(Class) && (
        obj <= Castkit::DataObject ||
          obj.ancestors.include?(Castkit::DSL::DataObject)
      )
    end

    # Returns a type caster lambda for the given type.
    #
    # Type casting performs both validation and deserialization on the provided value.
    #
    # @param type [Symbol] the registered type (e.g. :string)
    # @return [Proc] a lambda that accepts a value and options and returns a casted result
    def type_caster(type)
      type_definition = configuration.fetch_type(type)

      lambda do |value, validator: nil, options: {}, context: nil|
        type_definition.class.cast!(value, validator: validator, options: options, context: context)
      end
    end

    # Returns a serializer lambda for the given type.
    #
    # @param type [Symbol] the registered type (e.g. :string)
    # @return [Proc] a lambda that calls `.serialize` on the type
    def type_serializer(type)
      ->(value) { configuration.fetch_type(type).serialize(value) }
    end

    # Returns a deserializer lambda for the given type.
    #
    # @param type [Symbol] the registered type (e.g. :string)
    # @return [Proc] a lambda that calls `.deserialize` on the type
    def type_deserializer(type)
      ->(value) { configuration.fetch_type(type).deserialize(value) }
    end

    # Returns a validator lambda for the given type.
    #
    # @param type [Symbol] the registered type (e.g. :string)
    # @return [Proc] a lambda that calls `.validate!` on the type
    def type_validator(type)
      ->(value) { configuration.fetch_type(type).validate!(value) }
    end
  end
end

require_relative "configuration"
require_relative "plugins"
require_relative "inflector"
require_relative "version"
require_relative "attribute"
require_relative "contract"
require_relative "data_object"
