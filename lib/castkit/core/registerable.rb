# frozen_string_literal: true

require_relative "../castkit"

module Castkit
  module Core
    # Provides methods to register dynamically generated contracts and data objects
    # into the appropriate Castkit namespaces (`Castkit::Contracts`, `Castkit::DataObjects`).
    #
    # This is useful when working with ephemeral classes (e.g., from `Contract.build` or
    # `.to_dataobject`) that should be persisted and referenced as constants.
    #
    # @example Registering a contract class
    #   contract = Castkit::Contract.build(:user) { string :id }
    #   contract.extend(Castkit::Core::Registerable)
    #   contract.register! # => Castkit::Contracts::User
    #
    # @example Registering a DTO
    #   dto = contract.to_dataobject
    #   dto.extend(Castkit::Core::Registerable)
    #   dto.register!(as: :UserDto) # => Castkit::DataObjects::UserDto
    module Registerable
      CASTKIT_NAMESPACES = {
        contracts: Castkit::Contracts,
        dataobjects: Castkit::DataObjects
      }.freeze

      # Registers the current class in the specified Castkit namespace.
      #
      # @param namespace [Symbol] `:contracts` or `:dataobjects`
      # @param as [String, Symbol, nil] Optional constant name override (PascalCase).
      #   If not provided, falls back to the class's name (via `Inflector.pascalize(self.name)`).
      #
      # @raise [Castkit::Error] if class is anonymous or name already exists in the namespace
      # @return [Class] the registered class
      def register!(namespace:, as: nil)
        name = Castkit::Inflector.pascalize(as || self.name)
        raise Castkit::Error, "Unable to register anonymous classes, use as: ClassName" if name.nil?

        ns = Castkit.const_get(namespace.to_s.capitalize, false)
        raise Castkit::Error, "#{name} is already registered in #{ns}" if defined_in_namespace?(ns, name)

        ns.const_set(name, self)
        self
      end

      private

      # Checks whether a constant is already defined in the given namespace.
      #
      # @param namespace [Module] target module (e.g., `Castkit::Contracts`)
      # @param name [String, Symbol]
      # @return [Boolean]
      def defined_in_namespace?(namespace, name)
        namespace.const_defined?(name.to_s.to_sym, false)
      end
    end
  end
end
