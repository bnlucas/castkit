# frozen_string_literal: true

require "json"
require_relative "error"
require_relative "attribute"
require_relative "serializers/default_serializer"
require_relative "contract/validator"
require_relative "core/config"
require_relative "core/attributes"
require_relative "core/attribute_types"
require_relative "core/registerable"
require_relative "ext/data_object/contract"
require_relative "ext/data_object/deserialization"
require_relative "ext/data_object/plugins"
require_relative "ext/data_object/serialization"

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
    extend Castkit::Core::Config
    extend Castkit::Core::Attributes
    extend Castkit::Core::AttributeTypes
    extend Castkit::Core::Registerable
    extend Castkit::Ext::DataObject::Contract
    extend Castkit::Ext::DataObject::Plugins

    include Castkit::Ext::DataObject::Serialization
    include Castkit::Ext::DataObject::Deserialization

    class << self
      # Registers the current class under `Castkit::DataObjects`.
      #
      # @param as [String, Symbol, nil] The constant name to use (PascalCase). Defaults to class name or "Anonymous".
      # @return [Class] the registered dataobject class
      def register!(as: nil)
        super(namespace: :dataobjects, as: as)
      end

      def build(&block)
        klass = Class.new(self)
        klass.class_eval(&block) if block_given?

        klass
      end

      # Gets or sets the serializer class to use for instances of this object.
      #
      # @param value [Class<Castkit::Serializers::Base>, nil]
      # @return [Class<Castkit::Serializers::Base>, nil]
      # @raise [ArgumentError] if value does not inherit from Castkit::Serializers::Base
      def serializer(value = nil)
        if value
          unless value < Castkit::Serializers::Base
            raise ArgumentError, "Serializer must inherit from Castkit::Serializers::Base"
          end

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

    # @return [Hash{Symbol => Object}] The raw data provided during instantiation.
    attr_reader :__raw

    # @return [Hash{Symbol => Object}] Undefined attributes provided during instantiation.
    attr_reader :unknown_attributes

    # Initializes the DTO from a hash of attributes.
    #
    # @param data [Hash] raw input hash
    # @raise [Castkit::DataObjectError] if strict mode is enabled and unknown keys are present
    def initialize(data = {})
      @__raw = data.dup.freeze
      data = unwrap_root(data)

      @unknown_attributes = data.reject { |key, _| self.class.attributes.key?(key.to_sym) }.freeze

      validate_data!(data)
      deserialize_attributes!(data)
    end

    # Serializes the DTO to a Ruby hash.
    #
    # @param visited [Set, nil] used to track circular references
    # @return [Hash]
    def to_hash(visited: nil)
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

    # Helper method to call Castkit::Contract::Validator on the provided input data.
    #
    # @param data [Hash]
    # @raise [Castkit::ContractError]
    def validate_data!(data)
      Castkit::Contract::Validator.call!(
        self.class.attributes.values,
        data,
        **self.class.validation_rules
      )
    end

    # Returns the serializer instance or default for this object.
    #
    # @return [Class<Castkit::Serializers::Base>]
    def serializer
      @serializer ||= self.class.serializer || Castkit::Serializers::DefaultSerializer
    end

    # Returns false if self.class.allow_unknown == true, otherwise the value of self.class.strict.
    #
    # @return [Boolean]
    def strict?
      self.class.allow_unknown ? false : !!self.class.strict
    end
  end
end
