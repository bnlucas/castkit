# frozen_string_literal: true

require_relative "attribute/options"
require_relative "attribute/access"
require_relative "attribute/validation"

module Castkit
  module DSL
    # Provides a unified entry point for attribute-level DSL extensions.
    #
    # This module bundles together the core DSL modules for configuring attributes.
    # It is included internally by systems that support Castkit-style attribute declarations,
    # such as {Castkit::DataObject} and {Castkit::Contract::Base}.
    #
    # When included, it mixes in:
    # - {Castkit::DSL::Attribute::Options} – option-setting methods (e.g., `required`, `default`, etc.)
    # - {Castkit::DSL::Attribute::Access} – access control methods (e.g., `readonly`, `access`)
    # - {Castkit::DSL::Attribute::Validation} – validation helpers (e.g., `format`, `validator`)
    #
    # @example Extending a custom DSL that uses Castkit-style attributes
    #   class MyCustomSchema
    #     include Castkit::DSL::Attribute
    #
    #     def self.required(value)
    #       # interpret DSL options
    #     end
    #   end
    #
    #   class MyString < MyCustomSchema
    #     type :string
    #     required true
    #     access [:read]
    #   end
    #
    # @note This module is not intended to be mixed into {Castkit::Attributes::Definition}.
    module Attribute
      # Hook called when this module is included.
      #
      # @param base [Class, Module] the including class or module
      def self.included(base)
        base.include(Castkit::DSL::Attribute::Options)
        base.include(Castkit::DSL::Attribute::Access)
        base.include(Castkit::DSL::Attribute::Validation)
      end
    end
  end
end
