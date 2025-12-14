# frozen_string_literal: true

require_relative "base"

module Castkit
  module Serializers
    # Default serializer for Castkit::DataObject instances.
    #
    # Serializes attributes into a plain Ruby hash, applying access rules, nil/blank filtering,
    # and nested structure handling. The output format supports JSON-compatible structures
    # and respects the class-level serialization configuration.
    class DefaultSerializer < Castkit::Serializers::Base
      # @return [Hash{Symbol => Castkit::Attribute}] the attributes to serialize
      cattri :attributes, nil, expose: :read

      # @return [Hash{Symbol => Object}] unrecognized attributes captured during deserialization
      cattri :unknown_attributes, nil, expose: :read

      # @return [Hash] serialization config flags like :root, :ignore_nil, :allow_unknown
      cattri :options, nil, expose: :read

      # Serializes the object to a hash.
      #
      # Includes unknown attributes if configured, and wraps in a root key if defined.
      #
      # @return [Hash] the fully serialized result
      def call
        result = serialize_attributes
        result.merge!(unknown_attributes) if options[:allow_unknown]

        options[:root] ? { options[:root].to_sym => result } : result
      end

      private

      # Initializes the serializer.
      #
      # @param object [Castkit::DataObject] the object to serialize
      # @param visited [Set, nil] tracks circular references
      def initialize(object, visited: nil)
        super

        @skip_flag = "__castkit_#{object.object_id}"
        cattri_variable_set(:attributes, object.class.attributes.freeze)
        cattri_variable_set(:unknown_attributes, object.unknown_attributes.freeze)
        cattri_variable_set(:options, {
                              root: object.class.root,
                              ignore_nil: object.class.ignore_nil || false,
                              allow_unknown: object.class.allow_unknown || false
                            })
      end

      # Serializes all defined attributes.
      #
      # @return [Hash] serialized attribute key-value pairs
      def serialize_attributes
        attributes.values.each_with_object({}) do |attribute, hash|
          next if attribute.skip_serialization?

          serialized_value = serialize_attribute(attribute)
          next if serialized_value == @skip_flag

          assign_attribute_key!(attribute, serialized_value, hash)
        end
      end

      # Serializes a single attribute.
      #
      # @param attribute [Castkit::Attribute]
      # @return [Object] the serialized value or skip flag
      def serialize_attribute(attribute)
        value = object.public_send(attribute.field)
        return @skip_flag if skip_nil?(attribute, value)

        serialized_value = process_attribute(attribute, value)
        return @skip_flag if skip_blank?(attribute, serialized_value)

        serialized_value
      end

      # Delegates serialization based on type.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object]
      # @return [Object]
      def process_attribute(attribute, value)
        if attribute.dataobject?
          serialize_dataobject(attribute, value)
        elsif attribute.dataobject_collection?
          Array(value).map { |v| serialize_dataobject(attribute, v) }
        else
          type = Array(attribute.type).first
          Castkit.type_serializer(type).call(value)
        end
      end

      # Assigns value into nested hash structure based on key path.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object]
      # @param hash [Hash]
      # @return [void]
      def assign_attribute_key!(attribute, value, hash)
        key_path = attribute.key_path
        last = key_path.pop
        current = hash

        key_path.each do |key|
          current[key] ||= {}
          current = current[key]
        end

        current[last] = value
      end

      # Whether to skip serialization for nil values.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object]
      # @return [Boolean]
      def skip_nil?(attribute, value)
        value.nil? && (attribute.ignore_nil? || options[:ignore_nil])
      end

      # Whether to skip serialization for blank values.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Object]
      # @return [Boolean]
      def skip_blank?(attribute, value)
        blank?(value) && (attribute.ignore_blank? || options[:ignore_blank])
      end

      # True if value is nil or empty.
      #
      # @param value [Object]
      # @return [Boolean]
      def blank?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      # Serializes a DataObject using the proper serializer.
      #
      # @param attribute [Castkit::Attribute]
      # @param value [Castkit::DataObject]
      # @return [Object]
      def serialize_dataobject(attribute, value)
        serializer = attribute.options[:serializer]
        serializer ||= value.class.serializer
        serializer ||= Castkit::Serializers::DefaultSerializer

        serializer.call(value, visited: visited)
      end
    end
  end
end
