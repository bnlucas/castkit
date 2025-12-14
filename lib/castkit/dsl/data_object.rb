# frozen_string_literal: true

require_relative "../core/config"
require_relative "../core/attributes"
require_relative "../core/attribute_types"
require_relative "data_object/contract"
require_relative "data_object/plugins"
require_relative "data_object/serialization"
require_relative "data_object/deserialization"
require_relative "data_object/introspection"

module Castkit
  module DSL
    # Provides the complete DSL used by Castkit data objects.
    #
    # This module can be included into any class to make it behave like a `Castkit::DataObject`
    # without requiring subclassing. It wires in the full attribute DSL, type system, contract support,
    # plugin lifecycle, and (de)serialization logic.
    #
    # This is what powers `Castkit::DataObject` internally, and is intended for advanced use
    # cases where composition is preferred over inheritance.
    #
    # When included, this module:
    #
    # - `extend`s:
    #   - {Castkit::Core::Config} – configuration and context behavior
    #   - {Castkit::Core::Attributes} – the DSL for declaring attributes
    #   - {Castkit::Core::AttributeTypes} – support for custom type resolution
    #   - {Castkit::DSL::DataObject::Contract} – validation contract hooks
    #   - {Castkit::DSL::DataObject::Plugins} – plugin hooks and lifecycle events
    #
    # - `include`s:
    #   - {Castkit::DSL::DataObject::Serialization} – `#to_h`, `#as_json`, etc.
    #   - {Castkit::DSL::DataObject::Deserialization} – `from_h`, `from_json`, etc.
    #
    # @example Including in a custom data object
    #   class MyObject
    #     include Castkit::DSL::DataObject
    #
    #     string :id
    #     boolean :active, default: true
    #   end
    #
    # @see Castkit::DataObject for the default implementation
    module DataObject
      # Hook triggered when the module is included.
      #
      # @param base [Class] the including class
      # @return [void]
      def self.included(base)
        base.include(Cattri)

        base.extend(Castkit::Core::Config)
        base.extend(Castkit::Core::Attributes)
        base.extend(Castkit::Core::AttributeTypes)
        base.extend(Castkit::DSL::DataObject::Contract)
        base.extend(Castkit::DSL::DataObject::Plugins)
        base.extend(Castkit::DSL::DataObject::Introspection)

        base.include(Castkit::DSL::DataObject::Serialization)
        base.include(Castkit::DSL::DataObject::Deserialization)
      end
    end
  end
end
