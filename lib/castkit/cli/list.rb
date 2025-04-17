# frozen_string_literal: true

require "thor"
require "castkit"
require_relative "../../generators/contract"
require_relative "../../generators/data_object"
require_relative "../../generators/plugin"
require_relative "../../generators/serializer"
require_relative "../../generators/type"
require_relative "../../generators/validator"

module Castkit
  module CLI
    # CLI commands for listing internal Castkit registry components.
    #
    # Supports listing:
    # - Registered types (`castkit list types`)
    # - Available validators (`castkit list validators`)
    #
    # @example Show all available types
    #   $ castkit list types
    #
    # @example Show all defined validators
    #   $ castkit list validators
    class List < Thor
      desc "types", "Lists registered Castkit types"
      # Lists registered Castkit types, grouped into native and custom-defined.
      #
      # @return [void]
      def types
        all_keys = Castkit.configuration.types
        default_keys = Castkit::Configuration::DEFAULT_TYPES.keys

        native_types(all_keys, default_keys)
        custom_types(all_keys, default_keys)
      end

      desc "contracts", "Lists all generated Castkit contracts"
      # Lists all Castkit contract classes defined in the file system or registered under the Castkit namespace.
      #
      # @return [void]
      def contracts
        list_files("contracts")
      end

      desc "dataobjects", "Lists all generated Castkit DataObjects"
      # Lists all Castkit DataObjects classes defined in the file system or registered under the Castkit namespace.
      #
      # @return [void]
      def dataobjects
        list_files("data_objects")
      end

      desc "serializers", "Lists all generated Castkit serializers"
      # Lists all Castkit serializers classes defined in the file system or registered under the Castkit namespace.
      #
      # @return [void]
      def serializers
        list_files("serializers")
      end

      desc "validators", "Lists all generated Castkit validators"
      # Lists all Castkit validator classes defined in the file system or registered under the Castkit namespace.
      #
      # @return [void]
      def validators
        list_files("validators")
      end

      private

      # Prints all native types and their aliases.
      #
      # @param all_types [Hash<Symbol, Object>] all registered types
      # @param default_keys [Array<Symbol>] predefined native type keys
      # @return [void]
      def native_types(all_types, default_keys)
        alias_map = reverse_grouped(Castkit::Configuration::TYPE_ALIASES)
        native = all_types.slice(*default_keys)

        say "Native Types:", :green
        native.each do |name, type|
          aliases = alias_map[name] || []
          list_type(type.class, [name, *aliases].map(&:to_sym))
        end
      end

      # Prints all custom (non-native, non-alias) registered types.
      #
      # @param all_types [Hash<Symbol, Object>]
      # @param default_keys [Array<Symbol>]
      # @return [void]
      def custom_types(all_types, default_keys)
        alias_keys = Castkit::Configuration::TYPE_ALIASES.keys.map(&:to_sym)
        custom = all_types.except(*default_keys).reject { |k, _| alias_keys.include?(k) }

        say "\nCustom Types:", :green
        return no_custom_types if custom.empty?

        grouped_custom_types(custom)
      end

      # Outputs a fallback message if no custom types exist.
      #
      # @return [void]
      def no_custom_types
        say "  No registered types, register with " \
            "#{set_color("Castkit.configure { |c| c.register_type(:type, Type) }", :yellow)}"
      end

      # Groups and prints custom types by their class.
      #
      # @param types [Hash<Symbol, Object>]
      # @return [void]
      def grouped_custom_types(types)
        types.group_by { |_, inst| inst.class }.each do |klass, group|
          list_type(klass, group.map(&:first).map(&:to_sym))
        end
      end

      # Reverses a hash of alias => type into type => [aliases].
      #
      # @param hash [Hash]
      # @return [Hash{Symbol => Array<Symbol>}]
      def reverse_grouped(hash)
        hash.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(k, v), acc|
          acc[v] << k
        end
      end

      # Prints a type or class with all its symbol aliases.
      #
      # @param klass [Class]
      # @param keys [Array<Symbol>]
      # @return [void]
      def list_type(klass, keys)
        types = keys.uniq.sort.map { |k| set_color(":#{k}", :yellow) }.join(", ")
        say "  #{(klass.name || "<AnonymousType>").ljust(34)} - #{types}"
      end

      # Lists class references for a component (e.g. validators), distinguishing by source (file or custom).
      #
      # @param component [String] base namespace (e.g. "validators")
      # @return [void]
      def list_files(component)
        path = "lib/castkit/#{component}"
        all_classes, file_classes = component_classes(component, path)
        return say "No registered #{Castkit::Inflector.pascalize(component)} found." if all_classes.empty?

        max_width = all_classes.map(&:length).max + 5
        say "Castkit #{Castkit::Inflector.pascalize(component)}", :green

        all_classes.each do |klass|
          tag = file_classes.include?(klass) ? set_color("[Castkit]", :yellow) : set_color("[Custom]", :green)
          say "  #{klass.ljust(max_width)} #{tag}"
        end
      end

      # Gathers all registered and defined constants for a component.
      #
      # @param component [String]
      # @param path [String]
      # @return [Array<[Array<String>, Set<String>]>]
      def component_classes(component, path)
        namespace = Castkit.const_get(Castkit::Inflector.pascalize(component))
        file_classes = file_classes(namespace, path)
        defined_classes = defined_classes(namespace)

        all_classes = (file_classes + defined_classes).to_a.sort
        [all_classes, file_classes]
      end

      # Converts file names into class names for a given component.
      #
      # @param namespace [Module]
      # @param path [String]
      # @return [Set<String>]
      def file_classes(namespace, path)
        classes = Dir.glob("#{path}/*.rb")
                     .map { |f| File.basename(f, ".rb") }
                     .reject { |f| f.to_s == "base" }
                     .map { |base| "#{namespace}::#{Castkit::Inflector.pascalize(base)}" }

        classes.to_set
      end

      # Lists actual constants under a namespace, filtering out missing definitions.
      #
      # @param namespace [Module]
      # @return [Set<String>]
      def defined_classes(namespace)
        namespace.constants
                 .reject { |const| const.to_s == "Base" }
                 .map { |const| "#{namespace}::#{const}" }
                 .select { |klass| Object.const_defined?(klass) }
                 .to_set
      end
    end
  end
end
