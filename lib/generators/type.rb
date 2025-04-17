# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating a new Castkit type.
    #
    # Types define custom deserialization, serialization, and validation behavior
    # for attributes used in `Castkit::DataObject` or `Castkit::Contract`.
    #
    # Example usage:
    #   $ castkit generate type Money
    #
    # Generates:
    # - lib/castkit/types/money.rb
    # - spec/castkit/types/money_spec.rb
    #
    # These files scaffold a `Castkit::Types::Money` class inheriting from `Castkit::Types::Base`,
    # along with a basic RSpec test suite.
    #
    # @see Castkit::Generators::Base
    class Type < Castkit::Generators::Base
      component :type
    end
  end
end
