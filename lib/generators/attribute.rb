# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating Castkit attribute definitions.
    #
    # Generates a class inheriting from `Castkit::Attributes::Definition`
    # and an optional spec file.
    #
    # Example:
    #   $ castkit generate attribute OptionalString required:false default:"N/A"
    #
    # This will generate:
    # - lib/castkit/attributes/optional_string.rb
    # - spec/castkit/attributes/optional_string_spec.rb
    #
    # @see Castkit::Generators::Base
    class Attribute < Castkit::Generators::Base
      component :attribute

      argument :type,
               type: :string,
               desc: "The base type (e.g., string, integer)"

      private

      # @return [Hash] configuration passed into templates
      def config
        super.merge(
          type: type.first.gsub(/^:/, "")
        )
      end
    end
  end
end
