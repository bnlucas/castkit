# frozen_string_literal: true

require "set"

module Castkit
  # Abstract base class for defining custom serializers for Castkit::DataObject instances.
  #
  # Handles circular reference detection and provides a consistent `call` API.
  #
  # Subclasses must implement an instance method `#call` that returns a hash-like representation.
  #
  # @example Usage
  #   class CustomSerializer < Castkit::Serializer
  #     private
  #
  #     def call
  #       { type: obj.class.name, data: obj.to_h }
  #     end
  #   end
  #
  #   CustomSerializer.call(user_dto)
  class Serializer
    class << self
      # Entrypoint for serializing an object.
      #
      # @param obj [Castkit::DataObject] the object to serialize
      # @param visited [Set, nil] used to track visited object IDs
      # @return [Object] result of custom serialization
      def call(obj, visited: nil)
        new(obj, visited: visited).send(:serialize)
      end
    end

    # @return [Castkit::DataObject] the object being serialized
    attr_reader :obj

    protected

    # Fallback to the default serializer.
    #
    # @return [Hash]
    def serialize_with_default
      Castkit::DefaultSerializer.call(obj, visited: visited)
    end

    private

    # @return [Set<Integer>] a set of visited object IDs to detect circular references
    attr_reader :visited

    # Initializes the serializer instance.
    #
    # @param obj [Castkit::DataObject]
    # @param visited [Set, nil]
    def initialize(obj, visited: nil)
      @obj = obj
      @visited = visited || Set.new
    end

    # Subclasses must override this method to implement serialization logic.
    #
    # @raise [NotImplementedError]
    # @return [Object]
    def call
      raise NotImplementedError, "#{self.class.name} must implement `#call`"
    end

    # Wraps the actual serialization logic with circular reference detection.
    #
    # @return [Object]
    # @raise [Castkit::SerializationError] if a circular reference is detected
    def serialize
      check_circular_reference!
      visited << obj.object_id

      result = call
      visited.delete(obj.object_id)

      result
    end

    # Raises if the object has already been visited (circular reference).
    #
    # @raise [Castkit::SerializationError]
    # @return [void]
    def check_circular_reference!
      return unless visited.include?(obj.object_id)

      raise Castkit::SerializationError, "Circular reference detected for #{obj.class}"
    end
  end
end
