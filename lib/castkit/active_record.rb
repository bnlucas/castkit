# frozen_string_literal: true

module Castkit
  module ActiveRecord
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def model(model = nil)
        model ? (@model_class = model) : @model_class
      end

      def from_model(instance)
        raise ArgumentError, "No model defined for #{name}. Did you forget to call `model SomeModel`?" unless model
        raise ArgumentError, "Expected instance of #{model}, got #{instance.class}" unless instance.is_a?(model)

        attributes = instance.attributes.transform_keys(&:to_sym)
        filtered_attributes = attributes.slice(*attributes.keys)

        from_h(filtered_attributes)
      end

      # @param as [Castkit::DataObject]
      def from_relation(relation, eager_load: false, as: nil)
        dataobject = as || self
        raise ArgumentError, "Expected Enumerable" unless relation.respond_to?(:map)

        relation = relation.includes(*dataobject.nested_associations) if eager_load && relation.respond_to?(:includes)
        relation.map { |record| dataobject.from_model(record) }
      end

      def nested_associations
        attributes.values
                  .select { |attr| attr.dataobject? && !attr.composite? }
                  .map(&:name)
      end
    end

    PERSISTED_FIELDS = %i[id created_at updated_at].freeze

    def to_model(persisted: false)
      model = self.class.model or raise "No model defined for #{self.class.name}"

      hash = to_h
      hash = hash.reject { |key| PERSISTED_FIELDS.include?(key.to_sym) } unless persisted

      model.new(hash)
    end
  end
end
