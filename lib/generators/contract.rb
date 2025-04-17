# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating Castkit contracts.
    #
    # Generates a contract class and optionally a corresponding spec file.
    # Accepts an optional list of attribute definitions in the form `name:type`.
    #
    # Example:
    #   $ castkit generate contract User name:string age:integer
    #
    # This will generate:
    # - lib/castkit/contracts/user.rb
    # - spec/castkit/contracts/user_spec.rb
    #
    # @see Castkit::Generators::Base
    class Contract < Castkit::Generators::Base
      component :contract

      argument :fields, type: :array, default: [], desc: "Attribute definitions (e.g., name:string age:integer)"

      private

      # @return [Hash] configuration passed into templates
      def config
        super.merge(
          attributes: parsed_fields,
          default_values: default_values,
          invalid_types: invalid_types
        )
      end

      # Parses `name:type` fields into attribute definitions.
      #
      # @return [Array<Hash{Symbol => Object}>] list of parsed attribute hashes
      def parsed_fields
        fields.map do |field|
          name, type = field.split(":")
          { name: name, type: (type || "string").to_sym }
        end
      end

      # Default "invalid" test values for each supported type.
      #
      # Used in generated specs to simulate bad input.
      #
      # @return [Hash{Symbol => Object}]
      def invalid_types
        {
          string: true,
          integer: '"invalid"',
          float: '"bad"',
          boolean: '"not_a_bool"',
          date: 123,
          datetime: [],
          array: {},
          hash: [],
          uuid: 999
        }
      end
    end
  end
end
