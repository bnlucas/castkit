# frozen_string_literal: true

require_relative "serializer"

module Castkit
  # Default serializer for Castkit::DataObject instances.
  #
  # Serializes attributes into a plain Ruby hash, applying access rules, nil/blank filtering,
  # and nested structure handling. The output format supports JSON-compatible structures
  # and respects the class-level serialization configuration.
  class DefaultSerializer < Castkit::Serializer
    # @return [Hash{Symbol => Castkit::Attribute}] the attributes to serialize
    attr_reader :attributes

    # @return [Hash{Symbol => Object}] unrecognized attributes captured during deserialization
    attr_reader :unknown_attributes

    # @return [Hash] serialization config flags like :root, :ignore_nil, :allow_unknown
    attr_reader :options

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
    # @param obj [Castkit::DataObject] the object to serialize
    # @param visited [Set, nil] tracks circular references
    def initialize(obj, visited: nil)
      super

      @skip_flag = "__castkit_#{obj.object_id}"
      @attributes = obj.class.attributes.freeze
      @unknown_attributes = obj.unknown_attributes.freeze
      @options = {
        root: obj.class.root,
        ignore_nil: obj.class.ignore_nil || false,
        allow_unknown: obj.class.allow_unknown || false
      }
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
      value = obj.public_send(attribute.field)
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
      serializer ||= Castkit::DefaultSerializer

      serializer.call(value, visited: visited)
    end
  end
end
