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
  end
end
