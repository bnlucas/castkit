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

    # @return [Hash{Symbol => Object}] attributes that are not predefined or known to the object
    attr_reader :unknown_attributes

    # @return [Hash] serialization options (root key, ignore_nil, allow_unknown, etc.)
    attr_reader :options

    # Returns the serialized object as a Hash.
    #
    # Includes root wrapping if configured. If `allow_unknown` is set to true, unknown attributes
    # are merged into the final result.
    #
    # @return [Hash] The serialized object, potentially wrapped with a root key
    def call
      result = serialize_attributes
      result.merge!(unknown_attributes) if options[:allow_unknown]

      options[:root] ? { options[:root].to_sym => result } : result
    end

    private

    # Initializes the serializer with the target object and context.
    #
    # @param raw [Castkit::DataObject] the object to serialize
    # @param visited [Set, nil] used to detect circular references (default is nil)
    def initialize(raw, visited: nil)
      super

      # Setting up attributes, unknown attributes, and options based on the class-level configuration
      @attributes = raw.class.attributes
      @unknown_attributes = raw.unknown_attributes
      @options = {
        root: raw.class.root,
        ignore_nil: raw.class.ignore_nil || false,
        allow_unknown: raw.class.allow_unknown || false
      }
    end

    # Iterates over attributes and serializes each into a result hash.
    #
    # @return [Hash] The serialized attributes as a hash
    def serialize_attributes
      attributes.each_with_object({}) do |(_, attribute), hash|
        next if attribute.skip_serialization?

        # Serializing each attribute
        serialized_value = serialize_attribute(attribute)
        next if serialized_value == SKIP_ATTRIBUTE

        # Assign the serialized value to the correct key in the hash
        assign_attribute_key!(hash, attribute, serialized_value)
      end
    end

    # Process and serialize a given attribute.
    #
    # This handles value extraction, skipping when nil values are encountered, and ensuring
    # attributes are serialized according to their rules.
    #
    # @param attribute [Castkit::Attribute] The attribute instance to serialize
    # @return [Object, nil] The serialized value or SKIP_ATTRIBUTE if the value should be skipped
    def serialize_attribute(attribute)
      # Fetch the value of the attribute from the object
      value = obj.public_send(attribute.field)

      # Skip serialization if value is nil and ignore_nil is set to true
      return SKIP_ATTRIBUTE if value.nil? && (attribute.ignore_nil? || options[:ignore_nil])

      # Serialize the value using the attribute's dump method
      serialized_value = attribute.dump(value, visited: visited)

      # Skip if value is blank and ignore_blank is set to true
      return SKIP_ATTRIBUTE if blank?(serialized_value) && (attribute.ignore_blank? || options[:ignore_blank])

      serialized_value
    end

    # Assigns a serialized value into the hash using nested key paths.
    #
    # This ensures attributes with nested key paths (like `address.city`) are placed into nested hashes.
    #
    # @param hash [Hash] The resulting hash to populate with the serialized values
    # @param attribute [Castkit::Attribute] The attribute being serialized
    # @param value [Object] The serialized value
    # @return [void] Updates the hash in-place
    def assign_attribute_key!(hash, attribute, value)
      key_path = attribute.key_path
      last = key_path.pop
      current = hash

      # Traverse the key path and create nested hashes as needed
      key_path.each do |key|
        current[key] ||= {}
        current = current[key]
      end

      # Assign the final value to the last key in the path
      current[last] = value
    end

    # Determines if a value is blank (nil, empty array, empty hash, empty string, etc.)
    #
    # @param value [Object, nil] The value to check
    # @return [Boolean] true if the value is blank, false otherwise
    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end
