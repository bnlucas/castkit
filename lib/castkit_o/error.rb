# frozen_string_literal: true

module Castkit
  # Base error class for all Castkit-related exceptions.
  class Error < StandardError
    # @return [Hash, Object, nil] contextual data to aid in debugging
    attr_reader :context

    # Initializes a Castkit error.
    #
    # @param msg [String] the error message
    # @param context [Object, String, nil] optional data object or hash for context
    def initialize(msg, context: nil)
      super(msg)
      @context = context
    end
  end

  class TypeError < Error; end

  # Raised for issues related to Castkit::DataObject initialization or usage.
  class DataObjectError < Error; end

  class SerializerInheritanceError < Error
    def initialize
      super("Serializer must inherit from Castkit::Serializers::Base")
    end
  end

  # Raised for attribute validation, access, or casting failures.
  class AttributeError < Error
    # Returns the field name related to the error, if available.
    #
    # @return [Symbol, nil]
    def field
      context.is_a?(Hash) ? context[:field] : context || nil
    end

    # Formats the error message with field info if available.
    #
    # @return [String]
    def to_s
      field_info = field ? " (on #{field})" : ""
      "#{super}#{field_info}"
    end
  end

  # Raised during serialization if an object fails to serialize properly.
  class SerializationError < Error; end

  # Raised during contract validation.
  class ContractError < Error
    attr_reader :errors

    def initialize(msg, context: nil, errors: nil)
      super(msg, context: context)
      @errors = errors || {}
    end
  end
end
