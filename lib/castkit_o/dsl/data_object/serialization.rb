# frozen_string_literal: true

module Castkit
  module DSL
    module DataObject
      # Provides per-class serialization configuration for Castkit::Dataobject, including
      # root key handling and ignore rules.
      module Serialization
        # Returns the root key for this instance.
        #
        # @return [Symbol]
        def root_key
          return if root.nil?

          root.to_s.strip.to_sym
        end

        # Whether a root key is configured for this instance.
        #
        # @return [Boolean]
        def root_key_set?
          !!root_key && !root_key.empty?
        end
      end
    end
  end
end
