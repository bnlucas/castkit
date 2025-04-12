# frozen_string_literal: true

module Castkit
  module DataObjectExtensions
    # Provides per-class configuration for a Castkit::DataObject,
    # including root key handling, strict mode, and unknown key behavior.
    module Config
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
          @root = value.to_s.strip.to_sym if value
          @root
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
          @ignore_blank = value.nil? || value
        end

        # Sets or retrieves strict mode behavior.
        #
        # In strict mode, unknown keys during deserialization raise errors.
        #
        # @param value [Boolean, nil]
        # @return [Boolean]
        def strict(value = nil)
          if value.nil?
            @strict.nil? || @strict
          else
            @strict = value
          end
        end

        # Enables or disables ignoring unknown keys during deserialization.
        #
        # This is the inverse of `strict`.
        #
        # @param value [Boolean]
        # @return [void]
        def ignore_unknown(value = nil)
          @strict = !value
        end

        # Sets or retrieves whether to emit warnings when unknown keys are encountered.
        #
        # @param value [Boolean, nil]
        # @return [Boolean, nil]
        def warn_on_unknown(value = nil)
          value.nil? ? @warn_unknown_keys : (@warn_unknown_keys = value)
        end

        # Returns a relaxed version of the current class with strict mode off.
        #
        # Useful for tolerant parsing scenarios.
        #
        # @param warn_on_unknown [Boolean]
        # @return [Class] a subclass with relaxed rules
        def relaxed(warn_on_unknown: true)
          klass = Class.new(self)
          klass.strict(false)
          klass.warn_on_unknown(warn_on_unknown)
          klass
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
