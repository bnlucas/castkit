# frozen_string_literal: true

require_relative "options"

module Castkit
  module Attributes
    # Provides a class-based DSL for defining reusable attribute definitions.
    #
    # Extend this class in a subclass of `Castkit::Attributes::Base` to define
    # shared attribute settings that can be reused across multiple DataObjects.
    #
    # @example Defining a reusable attribute
    #   class UuidDefinition < Castkit::Attributes::Base
    #     type :string
    #     required true
    #     format /\A[0-9a-f\-]{36}\z/
    #   end
    #
    #   attribute :id, UuidDefinition.definition
    #
    class Definition
      extend Castkit::Attributes::Options

      class << self
        # @return [Hash] the internal definition hash, containing the type and options
        def definition
          @definition ||= {
            type: nil,
            options: Castkit::Attributes::Options::DEFAULTS.dup
          }
        end

        # @return [Hash] the attribute options defined on this class
        def options
          definition[:options]
        end

        # Defines the attribute's type and configuration using a DSL block.
        #
        # @param type [Symbol, Class<Castkit::DataObject>] the attribute type (e.g., :string, :integer)
        # @param options [Hash] additional options to merge after the block (e.g., default:, access:)
        # @yield DSL block used to set options like `required`, `format`, `readonly`, etc.
        # @return [Array<(Symbol, Hash)>] a tuple of the final type and options hash
        #
        # @example
        #   define :string, default: "none" do
        #     required true
        #     access [:read]
        #   end
        def define(type, **options, &block)
          @__castkit_attribute_dsl = true

          definition[:type] = type
          instance_eval(&block)
          definition[:options] = definition[:options].merge(options)

          definition
        ensure
          @__castkit_attribute_dsl = false
        end
      end
    end
  end
end
