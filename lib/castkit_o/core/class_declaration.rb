# frozen_string_literal: true

module Castkit
  module Core
    # Provides class-level DSL declarations with support for:
    #
    # - Defaults (static or callable)
    # - Coercion on assignment
    # - Optional instance-level readers
    # - Override tracking
    # - Inheritance-safe duplication
    #
    # This module is used by core Castkit DSL classes (e.g., DataObject) to define
    # structured metadata like `root`, `strict`, `serializer`, etc. These declarations
    # are introspectable, resettable, and safely inherited.
    #
    # @example
    #   class DslBase
    #     extend Castkit::Core::ClassDeclaration
    #
    #     declare :strict, default: false
    #     declare :serializer, default: MySerializer
    #     declare :root, coerce: ->(v) { v.to_sym }
    #   end
    module ClassDeclaration
      # A list of immutable value types that are safe to reuse directly without duplication.
      #
      # These types will be returned as-is when used as defaults.
      #
      # @return [Array<Class>]
      SAFE_VALUE_TYPES = [Numeric, Symbol, TrueClass, FalseClass, NilClass].freeze

      # Declares a class-level DSL property with optional default, coercion, and instance reader.
      #
      # @param name [Symbol] the name of the declaration (e.g. :strict)
      # @param default [Object, Proc, nil] a static value or proc returning the default
      # @param setter [Proc, nil] an optional block used in the defined setter
      # @param instance_reader [Boolean] whether to define an instance method (default: true)
      # @return [void]
      def declare(name, default: nil, setter: nil, instance_reader: true)
        default = safe_default(default)
        define_class_declaration_inheritance unless respond_to?(:__castkit_declarations)

        ivar = :"@#{name}"
        __castkit_declarations[name] = { ivar: ivar, default: default, setter: setter }

        define_accessors(ivar, name, default, setter, instance_reader: instance_reader)
      end

      # Returns a list of all declared class-level keys.
      #
      # @return [Array<Symbol>]
      def class_declarations
        __castkit_declarations.keys
      end

      # Checks whether a class-level declaration has been defined.
      #
      # @param name [Symbol]
      # @return [Boolean]
      def class_declaration?(name)
        __castkit_declarations.key?(name)
      end

      # Checks whether a class-level declaration has been explicitly overridden.
      #
      # @param name [Symbol]
      # @return [Boolean]
      def class_declaration_overridden?(name)
        !!@__castkit_declaration_set&.key?(name)
      end

      # Retrieves internal metadata for a given declaration.
      #
      # @param name [Symbol]
      # @return [Hash, nil]
      def class_declaration_for(name)
        __castkit_declarations[name]
      end

      # Resets all overridden declarations back to their default values.
      #
      # @return [void]
      def reset_class_declarations!
        @__castkit_declaration_set&.each_key do |name|
          reset_class_declaration!(name)
        end
      end

      # Resets a specific declaration back to its default value.
      #
      # @param name [Symbol]
      # @return [void]
      def reset_class_declaration!(name)
        return unless @__castkit_declaration_set&.key?(name)

        declaration = __castkit_declarations[name]
        value = declaration[:default].call

        instance_variable_set(declaration[:ivar], value)
        @__castkit_declaration_set&.delete(name)
      end

      private

      # Wraps static values in lambdas to ensure they are duplicated safely at runtime,
      # unless the value is known to be immutable or already a proc.
      #
      # @param default [Object, Proc, nil]
      # @return [Proc] a safe, memoizable proc
      def safe_default(default)
        return default if default.respond_to?(:call)
        return -> { default } if default.frozen? || SAFE_VALUE_TYPES.any? { |type| default.is_a?(type) }

        -> { default.dup }
      end

      # Defines the class-level getter/setter for a declared property.
      #
      # @param ivar [Symbol] the internal instance variable to store the value
      # @param name [Symbol] the method name
      # @param default [Proc] the normalized default proc
      # @param setter [Proc, nil] optional setter logic
      # @return [void]
      def define_accessors(ivar, name, default, setter, instance_reader:)
        define_singleton_method(name) do |*args|
          return instance_variable_get(ivar) if args.empty? && instance_variable_defined?(ivar)
          return instance_variable_set(ivar, default.call) if args.empty?

          value = setter ? setter.call(args.first) : args.first
          instance_variable_set(ivar, value)
          (@__castkit_declaration_set ||= {})[name] = true
        end

        return unless instance_reader && !method_defined?(name)

        define_method(name) { self.class.__send__(name) }
      end

      # Defines inheritance behavior for class declarations.
      #
      # Ensures each subclass receives an isolated copy of its parent’s declarations.
      #
      # @return [void]
      def define_class_declaration_inheritance
        unless singleton_class.method_defined?(:__castkit_declarations)
          define_singleton_method(:__castkit_declarations) { @__castkit_declarations ||= {} }
        end

        define_singleton_method(:inherited) do |subclass|
          super(subclass)
          subclass_declarations = {}

          __castkit_declarations.each do |name, options|
            apply_declaration!(subclass, subclass_declarations, name, options)
          end

          subclass.instance_variable_set(:@__castkit_declarations, subclass_declarations.freeze)
        end
      end

      # Copies a class declaration’s value and metadata into a subclass.
      #
      # @param subclass [Class] the subclass being initialized
      # @param declarations [Hash] the target declarations hash for the subclass
      # @param name [Symbol] the declaration key
      # @param options [Hash] the associated declaration options
      # @return [void]
      def apply_declaration!(subclass, declarations, name, options)
        value = instance_variable_get(options[:ivar])
        value = value.dup rescue value # rubocop:disable Style/RescueModifier

        subclass.instance_variable_set(options[:ivar], value)
        declarations[name] = options
      end
    end
  end
end
