# frozen_string_literal: true

module Castkit
  module DSL
    module DataObject
      # Adds deserialization support for Castkit::DataObject instances.
      #
      # Handles attribute loading, alias resolution, default fallback, nested DataObject casting,
      # unwrapped field extraction, and optional attribute enforcement.
      module Deserialization
        # Hooks in class methods like `.from_hash` when included.
        #
        # @param base [Class] the class including this module
        def self.included(base)
          base.extend(ClassMethods)
        end

        # Class-level deserialization helpers for Castkit::DataObject.
        module ClassMethods
          # Builds a new instance from a hash, symbolizing keys as needed.
          #
          # @param hash [Hash] input data
          # @return [Castkit::DataObject] deserialized instance
          def from_hash(hash)
            hash = hash.transform_keys { |k| k.respond_to?(:to_sym) ? k.to_sym : k }
            new(hash)
          end

          # @!method from_h(hash)
          #   Alias for {.from_hash}
          alias from_h from_hash

          # @!method deserialize(hash)
          #   Alias for {.from_hash}
          alias deserialize from_hash
        end

        private

        # Loads and assigns all attributes from input hash.
        #
        # @param input [Hash] the input data
        # @return [void]
        def deserialize_attributes!(input)
          self.class.attributes.each_value do |attribute|
            next if attribute.skip_deserialization?

            value = resolve_input_value(input, attribute)
            next if value.nil? && attribute.optional?

            value = deserialize_attribute_value!(attribute, value)
            assign_attribute_value!(attribute, value)
          end
        end

        # Deserializes an attribute's value according to its type.
        #
        # @param attribute [Castkit::Attribute]
        # @param value [Object]
        # @return [Object]
        def deserialize_attribute_value!(attribute, value)
          value = attribute.default if value.nil?
          raise Castkit::AttributeError, "#{attribute.field} cannot be nil" if required?(attribute, value)

          if attribute.dataobject?
            attribute.type.cast(value)
          elsif attribute.dataobject_collection?
            Array(value).map { |v| attribute.options[:of].cast(v) }
          else
            deserialize_primitive_value!(attribute, value)
          end
        end

        # Attempts to deserialize a primitive or union-typed value.
        #
        # @param attribute [Castkit::Attribute]
        # @param value [Object]
        # @return [Object]
        # @raise [Castkit::AttributeError] if no type matches
        def deserialize_primitive_value!(attribute, value)
          Array(attribute.type).each do |type|
            return Castkit.type_deserializer(type).call(value)
          rescue Castkit::TypeError, Castkit::AttributeError
            next
          end

          raise Castkit::AttributeError,
                "#{attribute.field} could not be deserialized into any of #{attribute.type.inspect}"
        end

        # Checks whether an attribute is required and its value is nil.
        #
        # @param attribute [Castkit::Attribute]
        # @param value [Object]
        # @return [Boolean]
        def required?(attribute, value)
          value.nil? && attribute.required?
        end

        # Finds the first matching value for an attribute using key and alias paths.
        #
        # @param input [Hash]
        # @param attribute [Castkit::Attribute]
        # @return [Object, nil]
        def resolve_input_value(input, attribute)
          attribute.key_path(with_aliases: true).each do |path|
            value = path.reduce(input) do |memo, key|
              next memo unless memo.is_a?(Hash)

              memo.key?(key) ? memo[key] : memo[key.to_s]
            end
            return value unless value.nil?
          end

          nil
        end

        # Stores a deserialized value using Cattri's internal store when available.
        #
        # @param attribute [Castkit::Attribute]
        # @param value [Object]
        # @return [void]
        def assign_attribute_value!(attribute, value)
          if respond_to?(:cattri_variable_set, true)
            cattri_variable_set(
              attribute.field,
              value,
              final: attribute.options[:final]
            )
          else
            instance_variable_set("@#{attribute.field}", value)
          end
        end

        # Resolves root-wrapped and unwrapped data.
        #
        # @param data [Hash]
        # @return [Hash] transformed input
        def unwrap_root(data)
          root = self.class.root
          data = data[root] if root && data.key?(root)

          unwrap_prefixed_fields!(data)
        end

        # Nests prefixed fields under their parent attribute for unwrapped dataobjects.
        #
        # @param data [Hash]
        # @return [Hash] modified input
        def unwrap_prefixed_fields!(data)
          self.class.attributes.each_value do |attribute|
            next unless attribute.unwrapped?

            unwrapped, keys_to_remove = unwrap_prefixed_values(data, attribute)
            next if unwrapped.empty?

            data[attribute.field] = unwrapped
            keys_to_remove.each { |k| data.delete(k) }
          end

          data
        end

        # Extracts and strips prefixed keys for unwrapped nested attributes.
        #
        # @param data [Hash]
        # @param attribute [Castkit::Attribute]
        # @return [Array<(Hash, Array<Symbol>)] extracted subhash and deleted keys
        def unwrap_prefixed_values(data, attribute)
          prefix = attribute.prefix.to_s
          unwrapped_data = {}
          keys_to_remove = []

          data.each do |k, v|
            k_str = k.to_s
            next unless k_str.start_with?(prefix)

            stripped = k_str.sub(prefix, "").to_sym
            unwrapped_data[stripped] = v
            keys_to_remove << k
          end

          [unwrapped_data, keys_to_remove]
        end
      end
    end
  end
end
