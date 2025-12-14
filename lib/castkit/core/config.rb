# frozen_string_literal: true

module Castkit
  module Core
    # Provides per-class configuration for a Castkit::DataObject,
    # including root key handling, strict mode, and unknown key behavior.
    module Config
      def self.extended(base)
        super

        base.include(Cattri) unless base.is_a?(Class) && base < Cattri
        return unless base.respond_to?(:cattri)

        base.cattri :strict_flag, nil, scope: :class, expose: :read_write
        base.cattri :warn_on_unknown_flag, nil, scope: :class, expose: :read_write
        base.cattri :allow_unknown_flag, nil, scope: :class, expose: :read_write
      end

      # Sets or retrieves strict mode behavior.
      #
      # In strict mode, unknown keys during deserialization raise errors. If unset, falls back
      # to `Castkit.configuration.strict_by_default`.
      #
      # @param value [Boolean, nil]
      # @return [Boolean]
      def strict(value = nil)
        return (strict_flag.nil? ? Castkit.configuration.strict_by_default : strict_flag) if value.nil?

        self.strict_flag = !!value
      end

      # Enables or disables ignoring unknown keys during deserialization.
      #
      # This is the inverse of `strict`.
      #
      # @param value [Boolean]
      # @return [void]
      def ignore_unknown(value = nil)
        self.strict_flag = !value
      end

      # Sets or retrieves whether to emit warnings when unknown keys are encountered.
      #
      # @param value [Boolean, nil]
      # @return [Boolean, nil]
      def warn_on_unknown(value = nil)
        value.nil? ? warn_on_unknown_flag : (self.warn_on_unknown_flag = value)
      end

      # Sets or retrieves whether to allow unknown keys when they are encountered.
      #
      # @param value [Boolean, nil]
      # @return [Boolean, nil]
      def allow_unknown(value = nil)
        value.nil? ? allow_unknown_flag : (self.allow_unknown_flag = value)
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

      # Returns a hash of config settings used during validation.
      #
      # @return [Hash{Symbol => Boolean}]
      def validation_rules
        @validation_rules ||= {}
        @validation_rules[:strict] = strict
        @validation_rules[:allow_unknown] = allow_unknown
        @validation_rules[:warn_on_unknown] = warn_on_unknown

        @validation_rules
      end
    end
  end
end
