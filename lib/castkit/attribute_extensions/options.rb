# frozen_string_literal: true

require_relative "../data_object"

module Castkit
  module AttributeExtensions
    # Provides access to normalized attribute options and helper predicates.
    #
    # These methods support Castkit attribute behavior such as default values,
    # key mapping, optionality, and structural roles (e.g. composite or unwrapped).
    module Options
      # Default options for attributes.
      #
      # @return [Hash<Symbol, Object>]
      DEFAULT_OPTIONS = {
        required: true,
        ignore_nil: false,
        ignore_blank: false,
        ignore: false,
        composite: false,
        unwrapped: false,
        prefix: nil,
        access: %i[read write]
      }.freeze

      # Returns the default value for the attribute.
      #
      # If the default is callable, it is invoked.
      #
      # @return [Object]
      def default
        val = @default
        val.respond_to?(:call) ? val.call : val
      end

      # Returns the serialization/deserialization key.
      #
      # Falls back to the field name if `:key` is not specified.
      #
      # @return [Symbol, String]
      def key
        options[:key] || field
      end

      # Returns the key path for accessing nested keys.
      #
      # Optionally includes alias key paths if `with_aliases` is true.
      #
      # @param with_aliases [Boolean]
      # @return [Array<Array<Symbol>>] nested key paths
      def key_path(with_aliases: false)
        path = key.to_s.split(".").map(&:to_sym) || []
        return path unless with_aliases

        [path] + alias_paths
      end

      # Returns all alias key paths as arrays of symbols.
      #
      # @return [Array<Array<Symbol>>]
      def alias_paths
        options[:aliases].map { |a| a.to_s.split(".").map(&:to_sym) }
      end

      # Whether the attribute is required for object construction.
      #
      # @return [Boolean]
      def required?
        options[:required]
      end

      # Whether the attribute is optional.
      #
      # @return [Boolean]
      def optional?
        !required?
      end

      # Whether to ignore `nil` values during serialization.
      #
      # @return [Boolean]
      def ignore_nil?
        options[:ignore_nil]
      end

      # Whether to ignore blank values (`[]`, `{}`, empty strings) during serialization.
      #
      # @return [Boolean]
      def ignore_blank?
        options[:ignore_blank]
      end

      # Whether the attribute is a nested Castkit::DataObject.
      #
      # @return [Boolean]
      def dataobject?
        Castkit.dataobject?(type)
      end

      # Whether the attribute is a collection of Castkit::DataObjects.
      #
      # @return [Boolean]
      def dataobject_collection?
        type == :array && Castkit.dataobject?(options[:of])
      end

      # Whether the attribute is considered composite (not exposed in serialized output).
      #
      # @return [Boolean]
      def composite?
        options[:composite]
      end

      # Whether the attribute is unwrapped into the parent object.
      #
      # Only applies to Castkit::DataObject types.
      #
      # @return [Boolean]
      def unwrapped?
        dataobject? && options[:unwrapped]
      end

      # Returns the prefix used for unwrapped attributes.
      #
      # @return [String, nil]
      def prefix
        options[:prefix]
      end
    end
  end
end
