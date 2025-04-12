# frozen_string_literal: true

module Castkit
  module DataObjectExtensions
    # Adds deserialization support for Castkit::DataObject instances.
    #
    # Handles attribute loading, alias resolution, and unwrapped field extraction.
    module Deserialization
      # Hooks in class methods like `.from_hash` when included.
      #
      # @param base [Class]
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class-level deserialization helpers.
      module ClassMethods
        # Builds a new instance from a Hash, symbolizing keys as needed.
        #
        # @param hash [Hash]
        # @return [Castkit::DataObject]
        def from_hash(hash)
          hash = hash.transform_keys { |k| k.respond_to?(:to_sym) ? k.to_sym : k }
          new(hash)
        end

        # @!method from_h(hash)
        #   Alias for {.from_hash}
        #
        # @!method creator(hash)
        #   Alias for {.from_hash}
        alias from_h from_hash
        alias creator from_hash
      end

      private

      # Loads attribute values from the given hash.
      #
      # Respects access control (e.g., `writeable?`) and uses `.load` for casting/validation.
      #
      # @param data [Hash]
      # @return [void]
      def deserialize_attributes!(data)
        self.class.attributes.each do |field, attribute|
          next if attribute.skip_deserialization?

          value = fetch_attribute_key(data, attribute)
          value = attribute.load(value, context: field)

          instance_variable_set("@#{field}", value)
        end
      end

      # Fetches the best matching value from the hash using attribute key and aliases.
      #
      # @param data [Hash]
      # @param attribute [Castkit::Attribute]
      # @return [Object]
      def fetch_attribute_key(data, attribute)
        attribute.key_path(with_aliases: true).each do |path|
          value = path.reduce(data) { |memo, key| memo.is_a?(Hash) ? memo[key] : nil }
          return value unless value.nil?
        end

        nil
      end

      # Extracts prefixed fields for unwrapped attributes and groups them under the original field key.
      #
      # @param data [Hash]
      # @return [Hash] modified input hash with unwrapped values nested under their base field
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

      # Returns the prefixed key-value pairs for a given unwrapped attribute.
      #
      # @param data [Hash]
      # @param attribute [Castkit::Attribute]
      # @return [Array<Hash, Array<Symbol>>] extracted key-value pairs and keys to delete
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
