# frozen_string_literal: true

require_relative "../../contract"

module Castkit
  module DSL
    module DataObject
      # Extension module that adds contract support to Castkit::DataObject classes.
      #
      # This allows any DataObject to be:
      # - Converted into a contract definition (via `.to_contract`)
      # - Validated against its contract (via `.validate` and `.validate!`)
      # - Reconstructed from a contract class (via `.from_contract`)
      #
      # Example:
      #
      #   class UserDto < Castkit::DataObject
      #     string :id
      #     string :email
      #   end
      #
      #   contract = UserDto.to_contract
      #   result = UserDto.validate(id: "abc")
      #
      #   UserDto.from_contract(contract) # => builds an equivalent DataObject class
      #
      # This module is automatically extended by Castkit::DataObject and is not intended
      # to be included manually.
      module Contract
        # Returns the associated Castkit::Contract for this DataObject.
        #
        # Memoizes the contract once it's built. Uses `to_contract` internally.
        #
        # @return [Class<Castkit::Contract::Definition>]
        def contract
          @contract ||= to_contract
        end

        # Converts the current DataObject into a Castkit::Contract subclass.
        #
        # If the contract has already been defined, returns the existing definition.
        # Otherwise, generates and registers a new contract class under Castkit::Contracts.
        #
        # @param as [String, Symbol, nil] Optional name for the contract.
        #   If omitted, inferred from the DataObject name.
        #
        # @return [Class<Castkit::Contract::Definition>] the generated or existing contract
        def to_contract(as: nil)
          Castkit::Contract.from_dataobject(self, as: as)
        end

        # Constructs a new Castkit::DataObject class from a given contract.
        #
        # This method is the inverse of `.to_contract` and provides a way to
        # generate a DataObject from an existing contract definition.
        #
        # @example
        #   UserContract = Castkit::Contract.build(:user) do
        #     string :id
        #     string :email
        #   end
        #
        #   UserDto = Castkit::DataObject.from_contract(UserContract)
        #   dto = UserDto.new(id: "abc", email: "a@example.com")
        #
        # @param contract [Class<Castkit::Contract::Base>] the contract to convert
        # @return [Class<Castkit::DataObject>] a new anonymous DataObject class

        def from_contract(contract)
          Class.new(Castkit::DataObject).tap do |klass|
            contract.attributes.each_value do |attr|
              klass.attribute(attr.field, attr.type, **attr.options)
            end
          end
        end

        # Validates input data using the contract associated with this DataObject.
        #
        # @param data [Hash] The input to validate
        # @return [Castkit::Contract::Result] the result of validation
        def validate(data)
          contract.validate(data)
        end

        # Validates input data and raises if validation fails.
        #
        # @param data [Hash] The input to validate
        # @raise [Castkit::ContractError] if validation fails
        # @return [void]
        def validate!(data)
          contract.validate!(data)
        end
      end
    end
  end
end
