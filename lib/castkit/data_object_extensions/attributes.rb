# frozen_string_literal: true

module Castkit
  module DataObjectExtensions
    # Provides DSL and implementation for declaring attributes within a Castkit::DataObject.
    #
    # Includes support for regular, composite, transient, readonly/writeonly, and grouped attribute definitions.
    module Attributes
      # Declares an attribute with the given type and options.
      #
      # If `:transient` is true, defines only standard accessors and skips serialization logic.
      #
      # @param field [Symbol]
      # @param type [Symbol, Class]
      # @param options [Hash]
      # @return [void]
      # @raise [Castkit::DataObjectError] if the attribute is already defined
      def attribute(field, type, **options)
        field = field.to_sym
        raise Castkit::DataObjectError, "Attribute '#{field}' already defined" if attributes.key?(field)

        options = build_options(options)
        return define_attribute(field, type, **options) unless options[:transient]

        attr_accessor field
      end

      # Declares a computed (composite) attribute.
      #
      # The provided block defines the read behavior.
      #
      # @param field [Symbol]
      # @param type [Symbol, Class]
      # @param options [Hash]
      # @yieldreturn [Object] evaluated composite value
      def composite(field, type, **options, &block)
        attribute(field, type, **options, composite: true)
        define_method(field, &block)
      end

      # Declares a group of transient attributes within the given block.
      #
      # These attributes are not serialized or included in `to_h`.
      #
      # @yield defines one or more transient attributes via `attribute`
      # @return [void]
      def transient(&block)
        @__transient_context = true
        instance_eval(&block)
      ensure
        @__transient_context = nil
      end

      # Declares a group of readonly attributes within the given block.
      #
      # @param options [Hash] shared options for attributes inside the block
      # @yield defines attributes with `access: [:read]`
      # @return [void]
      def readonly(**options, &block)
        with_access([:read], options, &block)
      end

      # Declares a group of writeonly attributes within the given block.
      #
      # @param options [Hash] shared options for attributes inside the block
      # @yield defines attributes with `access: [:write]`
      # @return [void]
      def writeonly(**options, &block)
        with_access([:write], options, &block)
      end

      # Declares a group of required attributes within the given block.
      #
      # @param options [Hash] shared options for attributes inside the block
      # @yield defines attributes with `required: true`
      # @return [void]
      def required(**options, &block)
        with_required(true, options, &block)
      end

      # Declares a group of optional attributes within the given block.
      #
      # @param options [Hash] shared options for attributes inside the block
      # @yield defines attributes with `required: false`
      # @return [void]
      def optional(**options, &block)
        with_required(false, options, &block)
      end

      # Returns all declared non-transient attributes.
      #
      # @return [Hash{Symbol => Castkit::Attribute}]
      def attributes
        @attributes ||= {}
      end

      # Alias for `composite`
      #
      # @see #composite
      alias property composite

      private

      # Defines a full attribute, including accessor methods and type logic.
      #
      # @param field [Symbol]
      # @param type [Symbol, Class]
      # @param options [Hash]
      def define_attribute(field, type, **options)
        attribute = Castkit::Attribute.new(field, type, **options)
        attributes[field] = attribute

        if attribute.full_access?
          attr_reader field

          define_typed_writer(field, attribute)
        elsif attribute.writeable?
          define_typed_writer(field, attribute)
        elsif attribute.readable?
          attr_reader field
        end
      end

      # Defines a type-aware writer method for the attribute.
      #
      # @param field [Symbol]
      # @param attribute [Castkit::Attribute]
      def define_typed_writer(field, attribute)
        define_method("#{field}=") do |value|
          casted = attribute.load(value, context: field)
          instance_variable_set("@#{field}", casted)
        end
      end

      # Applies scoped access control to all attributes declared in the given block.
      #
      # @param access [Array<Symbol>] e.g., [:read] or [:write]
      # @param options [Hash]
      # @yield the block containing one or more `attribute` calls
      def with_access(access, options = {}, &block)
        @__access_context = access
        @__block_options = options
        instance_eval(&block)
      ensure
        @__access_context = nil
        @__block_options = nil
      end

      # Applies scoped required/optional flag to all attributes declared in the given block.
      #
      # @param flag [Boolean]
      # @param options [Hash]
      # @yield the block containing one or more `attribute` calls
      def with_required(flag, options = {}, &block)
        @__required_context = flag
        @__block_options = options
        instance_eval(&block)
      ensure
        @__required_context = nil
        @__block_options = nil
      end

      # Builds effective options for the current attribute definition.
      #
      # Merges scoped flags like `required`, `access`, and `transient` if present.
      #
      # @param options [Hash]
      # @return [Hash]
      def build_options(options)
        base = @__block_options || {}
        base = base.merge(required: @__required_context) unless @__required_context.nil?
        base = base.merge(access: @__access_context) unless @__access_context.nil?
        base = base.merge(transient: true) if @__transient_context

        base.merge(options)
      end
    end
  end
end
