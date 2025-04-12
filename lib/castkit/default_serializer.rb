# frozen_string_literal: true

require_relative "serializer"

module Castkit
  # Default serializer for Castkit::DataObject instances.
  #
  # Serializes attributes based on access rules, nil/blank filtering, and nested structure.
  class DefaultSerializer < Castkit::Serializer
    SKIP_ATTRIBUTE = :__castkit_skip_attribute

    # @return [Hash{Symbol => Castkit::Attribute}] attributes to serialize
    attr_reader :attributes

    # @return [Hash] serialization options (root key, ignore_nil, etc.)
    attr_reader :options

    # Returns the serialized object as a Hash.
    #
    # Includes root wrapping if configured.
    #
    # @return [Hash]
    def call
      result = serialize_attributes
      options[:root] ? { options[:root].to_sym => result } : result
    end

    private

    # Initializes the serializer with the target object and context.
    #
    # @param raw [Castkit::DataObject] the object to serialize
    # @param visited [Set, nil] used to detect circular references
    def initialize(raw, visited: nil)
      super

      @attributes = raw.class.attributes
      @options = {
        root: raw.class.root,
        ignore_nil: raw.class.ignore_nil
      }
    end

    # Iterates over attributes and serializes each into a result hash.
    #
    # @return [Hash]
    def serialize_attributes
      attributes.each_with_object({}) do |(_, attribute), hash|
        next if attribute.skip_serialization?

        serialized_value = serialize_attribute(attribute)
        next if serialized_value == SKIP_ATTRIBUTE

        assign_attribute_key!(hash, attribute, serialized_value)
      end
    end

    # Process and serialize a given attribute.
    #
    # @param attribute [Castkit::Attribute] The attribute instance.
    # @param [Object]
    def serialize_attribute(attribute)
      value = obj.public_send(attribute.field)
      return SKIP_ATTRIBUTE if value.nil? && (attribute.ignore_nil? || options[:ignore_nil])

      serialized_value = attribute.dump(value, visited: visited)
      return SKIP_ATTRIBUTE if blank?(serialized_value) && (attribute.ignore_blank? || options[:ignore_blank])

      serialized_value
    end

    # Assigns a serialized value into the hash using nested key paths.
    #
    # @param hash [Hash]
    # @param attribute [Castkit::Attribute]
    # @param value [Object]
    # @return [void]
    def assign_attribute_key!(hash, attribute, value)
      key_path = attribute.key_path
      last = key_path.pop
      current = hash

      key_path.each do |key|
        current[key] ||= {}
        current = current[key]
      end

      current[last] = value
    end

    # Determines if a value is blank (nil or empty).
    #
    # @param value [Object, nil]
    # @return [Boolean]
    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value&.empty?)
    end
  end
end
