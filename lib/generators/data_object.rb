# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating Castkit DataObject classes.
    #
    # Generates a DataObject class and an optional spec file with attribute definitions.
    # Accepts a list of field definitions in the form `name:type`.
    #
    # Example:
    #   $ castkit generate dataobject User name:string active:boolean
    #
    # This will generate:
    # - lib/castkit/data_objects/user.rb
    # - spec/castkit/data_objects/user_spec.rb
    #
    # @see Castkit::Generators::Base
    class DataObject < Castkit::Generators::Base
      component :data_object

      argument :fields, type: :array, default: [], desc: "Attribute definitions (e.g., name:string active:boolean)"

      private

      # @return [Hash] configuration passed into templates
      def config
        super.merge(
          attributes: parsed_fields,
          default_values: default_values
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
    end
  end
end
