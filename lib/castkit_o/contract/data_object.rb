# frozen_string_literal: true

module Castkit
  module Contract
    # Extension module that adds `.to_dataobject` and `.dataobject` support to Castkit contracts.
    #
    # This allows any contract to be dynamically converted into a Castkit::DataObject class,
    # enabling reuse of validation schemas for serialization, coercion, or API response modeling.
    #
    # This module is automatically included by Castkit contract classes and is not
    # intended to be used manually.
    #
    # @example
    #   contract = Castkit::Contract.build(:user) do
    #     string :id
    #     string :email
    #   end
    #
    #   UserDto = contract.to_dataobject
    #   UserDto.new(id: "123", email: "a@example.com")
    module DataObject
      # Returns or builds a Castkit::DataObject from the current contract.
      #
      # Memoizes the result to avoid repeated regeneration.
      #
      # @example
      #   contract = Castkit::Contract.build(:user) do
      #     string :id
      #     string :name
      #   end
      #
      #   dto_class = contract.dataobject
      #   dto = dto_class.new(id: "123", name: "Alice")
      #
      # @return [Class<Castkit::DataObject>] the generated DTO class
      def dataobject
        @dataobject ||= to_dataobject
      end

      # Constructs an ephemeral Castkit::DataObject class from the current contract.
      #
      # This creates a new anonymous class each time unless memoized via {#dataobject}.
      #
      # @example
      #   dto_class = contract.to_dataobject
      #
      # @return [Class<Castkit::DataObject>] the dynamically generated DTO
      def to_dataobject
        Class.new(Castkit::DataObject).tap do |klass|
          attributes.each_value do |attr|
            klass.attribute(attr.field, attr.type, **attr.options)
          end
        end
      end

      # Alias for {#to_dataobject}
      #
      # @see #to_dataobject
      alias to_dto to_dataobject
    end
  end
end
