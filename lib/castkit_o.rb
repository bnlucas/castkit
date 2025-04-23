# frozen_string_literal: true

require_relative "castkit_o/castkit_o"
require_relative "castkit_o/core/class_declaration"

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
module Castkit; end
