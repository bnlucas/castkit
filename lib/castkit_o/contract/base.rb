# frozen_string_literal: true

require_relative "../core/config"
require_relative "../core/attribute_types"
require_relative "result"

module Castkit
  module Contract
    # Base class for all Castkit contracts.
    #
    # Castkit contracts define validation logic over a set of attributes using a DSL.
    # You can either subclass this directly or use {Castkit::Contract.build} to generate
    # ephemeral or reusable contract classes.
    #
    # @example Subclassing directly
    #   class MyContract < Castkit::Contract::Base
    #     string :id
    #     integer :count, required: false
    #   end
    #
    #   MyContract.validate!(id: "abc")
    #
    # @example Using Contract.build (preferred for dynamic generation)
    #   UserContract = Castkit::Contract.build(:user) do
    #     string :id
    #     string :email, required: false
    #   end
    #
    #   UserContract.validate!(id: "123")
    #
    # @see Castkit::Contract.build
    class Base
      extend Castkit::Core::Config
      extend Castkit::Core::AttributeTypes

      ATTRIBUTE_OPTIONS = %i[
        required aliases min max format of validator unwrapped prefix force_type
      ].freeze

      class << self
        # Defines an attribute for the contract.
        #
        # Only a subset of options is allowed inside a contract.
        #
        # @param field [Symbol] the field name
        # @param type [Symbol, Class, Array] the type or union of types
        # @param options [Hash] allowed options like :required or :validator
        # @return [void]
        def attribute(field, type, **options)
          options = options.slice(*ATTRIBUTE_OPTIONS)
          attributes[field] = Castkit::Attribute.new(field, type, **options)
        end

        # Validates input against the contract and returns a Result.
        #
        # @param input [Hash]
        # @return [Castkit::Contract::Result]
        def validate(input)
          validate!(input)
        rescue Castkit::ContractError => e
          Castkit::Contract::Result.new(definition[:name].to_s, input, errors: e.errors)
        end

        # Validates input and raises on failure.
        #
        # @param input [Hash]
        # @raise [Castkit::ContractError]
        # @return [void]
        def validate!(input)
          Castkit::Contract::Validator.call!(attributes.values, input, **validation_rules)
          Castkit::Contract::Result.new(definition[:name].to_s, input)
        end

        # Returns internal contract metadata.
        #
        # @return [Hash]
        def definition
          @definition ||= {
            name: :ephemeral,
            attributes: {}
          }
        end

        # Returns the defined attributes.
        #
        # @return [Hash{Symbol => Castkit::Attribute}]
        def attributes
          definition[:attributes]
        end

        private

        # Defines the contract from a source or block.
        #
        # @param name [Symbol, String]
        # @param source [Castkit::DataObject, nil]
        # @param block [Proc, nil]
        # @return [Hash]
        def define(name = :ephemeral, source = nil, validation_rules: {}, &block)
          validate_definition!(source, &block)

          if source
            define_from_source(name, source)
          else
            define_from_block(name, &block)
          end

          validation_rules.each { |k, v| self.validation_rules[k] = v }
          attributes
        end

        # Copies attributes from a DataObject.
        #
        # @param name [Symbol, String]
        # @param source [Castkit::DataObject]
        # @return [void]
        def define_from_source(name, source)
          source_attributes = source.attributes.dup

          @definition = {
            name: name,
            attributes: source_attributes.transform_values do |attr|
              Castkit::Attribute.new(attr.field, attr.type, **attr.options.slice(*ATTRIBUTE_OPTIONS))
            end
          }
        end

        # Executes DSL block in the contract context.
        #
        # @param name [Symbol, String]
        # @yield [block]
        # @return [void]
        def define_from_block(name, &block)
          definition[:name] = name

          @__castkit_contract_dsl = true
          instance_eval(&block)
        ensure
          @__castkit_contract_dsl = false
        end

        # Ensures a valid contract definition input.
        #
        # @param source [Object, nil]
        # @raise [Castkit::ContractError]
        # @return [void]
        def validate_definition!(source)
          raise Castkit::ContractError, "Received both source and block" if source && block_given?
          return if block_given? || Castkit.dataobject?(source)

          raise Castkit::ContractError, "Expected a Castkit::DataObject or contract block"
        end
      end
    end
  end
end
