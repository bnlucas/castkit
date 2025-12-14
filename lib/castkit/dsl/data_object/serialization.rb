# frozen_string_literal: true

module Castkit
  module DSL
    module DataObject
      # Provides per-class serialization configuration for Castkit::Dataobject, including
      # root key handling and ignore rules.
      module Serialization
        # Automatically extends class-level methods when included.
        #
        # @param base [Class]
        def self.included(base)
          base.extend(ClassMethods)
        end

        # Class-level configuration methods.
        module ClassMethods
          # Sets or retrieves the root key to wrap the object under during (de)serialization.
          #
          # @param value [String, Symbol, nil] optional root key
          # @return [Symbol, nil]
          def root(value = nil)
            value.nil? ? @root : (@root = value.to_s.strip.to_sym)
          end

          # Sets or retrieves whether to skip `nil` values in output.
          #
          # @param value [Boolean, nil]
          # @return [Boolean, nil]
          def ignore_nil(value = nil)
            value.nil? ? @ignore_nil : (@ignore_nil = value)
          end

          # Sets or retrieves whether to skip blank values (`[]`, `{}`, `""`, etc.) in output.
          #
          # Defaults to true unless explicitly set to false.
          #
          # @param value [Boolean, nil]
          # @return [Boolean]
          def ignore_blank(value = nil)
            return (@ignore_blank = true) if value.nil? && !defined?(@ignore_blank)
            return @ignore_blank if value.nil?

            @ignore_blank = value
          end
        end

        # Returns the root key for this instance.
        #
        # @return [Symbol]
        def root_key
          self.class.root.to_s.strip.to_sym
        end

        # Whether a root key is configured for this instance.
        #
        # @return [Boolean]
        def root_key_set?
          !self.class.root.to_s.strip.empty?
        end
      end
    end
  end
end
