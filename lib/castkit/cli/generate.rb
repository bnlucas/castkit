# frozen_string_literal: true

require "thor"
require_relative "../../generators/contract"
require_relative "../../generators/data_object"
require_relative "../../generators/plugin"
require_relative "../../generators/serializer"
require_relative "../../generators/type"
require_relative "../../generators/validator"

module Castkit
  module CLI
    # Thor CLI class for generating Castkit components.
    #
    # Provides `castkit generate` commands for each major Castkit component, including types,
    # data objects, contracts, validators, serializers, and plugins.
    #
    # All generators support the `--no-spec` flag to skip spec file creation.
    class Generate < Thor
      desc "contract NAME", "Generates a new Castkit contract"
      method_option :spec, type: :boolean, default: true
      # Generates a new contract class.
      #
      # @param name [String] the class name for the contract
      # @param fields [Array<String>] optional attribute definitions
      # @return [void]
      def contract(name, *fields)
        args = [Castkit::Inflector.pascalize(name), fields]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::Contract.start(args)
      end

      desc "dataobject NAME", "Generates a new Castkit DataObject"
      method_option :spec, type: :boolean, default: true
      # Generates a new DataObject class.
      #
      # @param name [String] the class name for the data object
      # @param fields [Array<String>] optional attribute definitions
      # @return [void]
      def dataobject(name, *fields)
        args = [Castkit::Inflector.pascalize(name), fields]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::DataObject.start(args)
      end

      desc "plugin NAME", "Generates a new Castkit plugin"
      method_option :spec, type: :boolean, default: true
      # Generates a new plugin module.
      #
      # @param name [String] the module name for the plugin
      # @param fields [Array<String>] optional stub fields
      # @return [void]
      def plugin(name, *fields)
        args = [Castkit::Inflector.pascalize(name), fields]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::Plugin.start(args)
      end

      desc "serializer NAME", "Generates a new Castkit serializer"
      method_option :spec, type: :boolean, default: true
      # Generates a new custom serializer class.
      #
      # @param name [String] the class name for the serializer
      # @param fields [Array<String>] optional stub fields
      # @return [void]
      def serializer(name, *fields)
        args = [Castkit::Inflector.pascalize(name), fields]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::Serializer.start(args)
      end

      desc "type NAME", "Generates a new Castkit type"
      method_option :spec, type: :boolean, default: true
      # Generates a new custom type.
      #
      # @param name [String] the class name for the type
      # @return [void]
      def type(name)
        args = [Castkit::Inflector.pascalize(name)]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::Type.start(args)
      end

      desc "validator NAME", "Generates a new Castkit validator"
      method_option :spec, type: :boolean, default: true
      # Generates a new validator class.
      #
      # @param name [String] the class name for the validator
      # @param fields [Array<String>] optional stub fields
      # @return [void]
      def validator(name, *fields)
        args = [Castkit::Inflector.pascalize(name), fields]
        args << "--no-spec" unless options[:spec]
        Castkit::Generators::Validator.start(args)
      end
    end
  end
end
