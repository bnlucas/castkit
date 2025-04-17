# frozen_string_literal: true

require_relative "contract/base"

module Castkit
  # Castkit::Contract provides a lightweight mechanism for defining and validating
  # structured input using a DSL similar to Castkit::DataObject, but without requiring
  # a full data model. Contracts are ideal for validating operation inputs, service payloads,
  # or external API request data.
  #
  # Contracts support primitive type coercion, nested data object validation, and configurable
  # strictness for unknown attributes. Each contract is defined as a standalone class
  # with its own rules and validation logic.
  module Contract
    class << self
      # Builds a contract from a DSL block and optional validation rules.
      #
      # @example Using a block to define a contract
      #   UserContract = Castkit::Contract.build(:user) do
      #     string :id
      #     string :email, required: false
      #   end
      #
      #   UserContract.validate!(id: "abc") # => passes
      #
      # @example With custom validation rules
      #   LooseContract = Castkit::Contract.build(:loose, strict: false) do
      #     string :token
      #   end
      #
      # @param name [String, Symbol, nil] Optional name for the contract.
      # @param validation_rules [Hash] Optional validation rules (e.g., `strict: true`).
      # @yield Optional DSL block to define attributes.
      # @return [Class<Castkit::Contract::Base>]
      def build(name = nil, **validation_rules, &block)
        klass = Class.new(Castkit::Contract::Base)
        klass.send(:define, name, nil, validation_rules: validation_rules, &block)

        klass
      end

      # Builds a contract from an existing Castkit::DataObject class.
      #
      # @example Generating a contract from a DTO
      #   class UserDto < Castkit::DataObject
      #     string :id
      #     string :email
      #   end
      #
      #   UserContract = Castkit::Contract.from_dataobject(UserDto)
      #   UserContract.validate!(id: "123", email: "a@example.com")
      #
      # @param source [Class<Castkit::DataObject>] the DataObject to generate the contract from
      # @param as [String, Symbol, nil] Optional custom name to use for the contract
      # @return [Class<Castkit::Contract::Base>]
      def from_dataobject(source, as: nil)
        name = as || Castkit::Inflector.unqualified_name(source)
        name = Castkit::Inflector.underscore(name).to_sym

        klass = Class.new(Castkit::Contract::Base)
        klass.send(:define, name, source, validation_rules: source.validation_rules)

        klass
      end
    end
  end
end
