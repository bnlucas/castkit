# frozen_string_literal: true

require "json"
require_relative "error"
require_relative "attribute"
require_relative "default_serializer"
require_relative "data_object_extensions/config"
require_relative "data_object_extensions/attributes"
require_relative "data_object_extensions/attribute_types"
require_relative "data_object_extensions/deserialization"

module Castkit
  # Base class for defining declarative, typed data transfer objects (DTOs).
  #
  # Includes typecasting, validation, access control, serialization, deserialization,
  # and support for custom serializers.
  #
  # @example Defining a DTO
  #   class UserDto < Castkit::DataObject
  #     string :name
  #     integer :age, required: false
  #   end
  #
  # @example Instantiating and serializing
  #   user = UserDto.new(name: "Alice", age: 30)
  #   user.to_json #=> '{"name":"Alice","age":30}'
  class DataObject
    extend Castkit::DataObjectExtensions::Attributes
    extend Castkit::DataObjectExtensions::AttributeTypes

    include Castkit::DataObjectExtensions::Config
    include Castkit::DataObjectExtensions::Deserialization

    class << self
      # Gets or sets the serializer class to use for instances of this object.
      #
      # @param value [Class<Castkit::Serializer>, nil]
      # @return [Class<Castkit::Serializer>, nil]
      # @raise [ArgumentError] if value does not inherit from Castkit::Serializer
      def serializer(value = nil)
        if value
          raise ArgumentError, "Serializer must inherit from Castkit::Serializer" unless value < Castkit::Serializer

          @serializer = value
        else
          @serializer
        end
      end

      # Casts a value into an instance of this class.
      #
      # @param obj [self, Hash]
      # @return [self]
      # @raise [Castkit::DataObjectError] if obj is not castable
      def cast(obj)
        case obj
        when self
          obj
        when Hash
          from_h(obj)
        else
          raise Castkit::DataObjectError, "Can't cast #{obj.class} to #{name}"
        end
      end

      # Converts an object to its JSON representation.
      #
      # @param obj [Castkit::DataObject]
      # @return [String]
      def dump(obj)
        obj.to_json
      end
    end

    # Initializes the DTO from a hash of attributes.
    #
    # @param fields [Hash] raw input hash
    # @raise [Castkit::DataObjectError] if strict mode is enabled and unknown keys are present
    def initialize(fields = {})
      root = self.class.root
      fields = fields[root] if root && fields.key?(root)
      fields = unwrap_prefixed_fields!(fields)

      validate_keys!(fields)
      deserialize_attributes!(fields)
    end

    # Serializes the DTO to a Ruby hash.
    #
    # @param visited [Set, nil] used to track circular references
    # @return [Hash]
    def to_hash(visited: nil)
      serializer = self.class.serializer || Castkit::DefaultSerializer
      serializer.call(self, visited: visited)
    end

    # Serializes the DTO to a JSON string.
    #
    # @param options [Hash, nil] options passed to `JSON.generate`
    # @return [String]
    def to_json(options = nil)
      JSON.generate(serializer.call(self), options)
    end

    # @!method to_h
    #   Alias for {#to_hash}
    #
    # @!method serialize
    #   Alias for {#to_hash}
    alias to_h to_hash
    alias serialize to_hash

    private

    # Validates that the input only contains known keys unless configured otherwise.
    #
    # @param data [Hash]
    # @raise [Castkit::DataObjectError] in strict mode if unknown keys are present
    # @return [void]
    def validate_keys!(data)
      valid_keys = self.class.attributes.flat_map do |_, attr|
        [attr.key] + attr.options[:aliases]
      end.map(&:to_sym).uniq

      unknown_keys = data.keys.map(&:to_sym) - valid_keys
      return if unknown_keys.empty?

      handle_unknown_keys!(unknown_keys)
    end

    # Handles unknown keys found during initialization.
    #
    # Behavior depends on the class-level configuration:
    # - Raises a `Castkit::DataObjectError` if strict mode is enabled.
    # - Logs a warning if `warn_on_unknown` is enabled.
    #
    # @param unknown_keys [Array<Symbol>] list of unknown keys not declared as attributes or aliases
    # @raise [Castkit::DataObjectError] if strict mode is active
    # @return [void]
    def handle_unknown_keys!(unknown_keys)
      raise Castkit::DataObjectError, "Unknown attribute(s): #{unknown_keys.join(", ")}" if self.class.strict

      warn "⚠️  [Castkit] Unknown attribute(s) ignored: #{unknown_keys.join(", ")}" if self.class.warn_on_unknown
    end

    # Returns the serializer instance or default for this object.
    #
    # @return [Class<Castkit::Serializer>]
    def serializer
      @serializer ||= self.class.serializer || Castkit::DefaultSerializer
    end
  end
end
