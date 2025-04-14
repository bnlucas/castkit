# frozen_string_literal: true

require_relative "configuration"

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
module Castkit
  class << self
    # Yields the global configuration object for customization.
    #
    # @example
    #   Castkit.configure do |config|
    #     config.enforce_boolean_casting = false
    #   end
    #
    # @yieldparam config [Castkit::Configuration]
    # @return [void]
    def configure
      yield(configuration)
    end

    # Retrieves the global Castkit configuration.
    #
    # @return [Castkit::Configuration] the configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Generates a warning message if configuration.enable_warnings == true.
    #
    # @param message [String] The warning message
    # @return [void]
    def warning(message)
      warn message if configuration.enable_warnings
    end

    # Determine if an object is a subclass of Castkit::DataObject.
    #
    # @param obj [Object] The object to check
    # @return [Boolean]
    def dataobject?(obj)
      obj.is_a?(Class) && obj.ancestors.include?(Castkit::DataObject)
    end
  end
end
