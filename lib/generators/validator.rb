# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating a new Castkit validator.
    #
    # Validators are responsible for asserting that a given value conforms to a rule.
    # They are typically used inside a type’s `#validate!` method or within custom contract logic.
    #
    # Example usage:
    #   $ castkit generate validator Money
    #
    # Generates:
    # - lib/castkit/validators/money.rb
    # - spec/castkit/validators/money_spec.rb
    #
    # These files scaffold a `Castkit::Validators::Money` class with a `#call` method
    # and a corresponding RSpec test suite.
    #
    # @see Castkit::Generators::Base
    class Validator < Castkit::Generators::Base
      component :validator

      private

      # Provides extra context used within ERB templates for this generator.
      #
      # @return [Hash]
      def config
        super.merge(
          default_value: "example",
          sample_context: "field_name"
        )
      end
    end
  end
end
