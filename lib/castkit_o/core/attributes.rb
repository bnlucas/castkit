# frozen_string_literal: true

module Castkit
  module Core
    # Provides DSL and implementation for declaring attributes within a Castkit::DataObject.
    #
    # Supports reusable attribute definitions, transient fields, composite readers, and
    # grouped declarations such as `readonly`, `optional`, and `transient` blocks.
    #
    # This module is included into `Castkit::DataObject` and handles attribute registration,
    # accessor generation, and typed writing behavior.
    module Attributes
      # Declares an attribute on the data object.
      #
      # Accepts either inline options or a reusable attribute definition (`using` or `definition`).
      # If `:transient` is true, defines only standard accessors and skips serialization logic.
      #
      # @param field [Symbol] the attribute name
      # @param type [Symbol, Class] the attribute's declared type
      # @param definition [Hash, nil] an optional pre-built definition object (`{ type:, options: }`)
      # @param using [Castkit::Attributes::Base, nil] an optional class-based definition (`.definition`)
      # @param options [Hash] additional options like `default`, `access`, `required`, etc.
      # @return [void]
      # @raise [Castkit::DataObjectError] if attribute already defined or type mismatch
      def attribute(field, type = nil, definition = nil, using: nil, **options)
        field = field.to_sym
        raise Castkit::DataObjectError, "Attribute '#{field}' already defined" if attributes.key?(field)

        type, options = use_definition(field, definition || using&.definition, type, options)
        return define_attribute(field, type, **options) unless options[:transient]

        attr_accessor field
      end

      # Declares a composite (computed) attribute.
      #
      # @param field [Symbol] the name of the attribute
      # @param type [Symbol, Class] the attribute type
      # @param options [Hash] additional attribute options
      # @yieldreturn [Object] the value to return when the reader is called
      # @return [void]
      def composite(field, type, **options, &block)
        attribute(field, type, **options, composite: true)
        define_method(field, &block)
      end

      # Declares a group of transient attributes within a block.
      #
      # These attributes are excluded from serialization (`to_h`) and not stored.
      #
      # @yield a block containing `attribute` calls
      # @return [void]
      def transient(&block)
        @__transient_context = true
        instance_eval(&block)
      ensure
        @__transient_context = nil
      end

      # Declares a group of readonly attributes (accessible for read only).
      #
      # @param options [Hash] shared options for all attributes inside the block
      # @yield a block containing `attribute` calls
      # @return [void]
      def readonly(**options, &block)
        with_access([:read], options, &block)
      end

      # Declares a group of writeonly attributes (accessible for write only).
      #
      # @param options [Hash] shared options for all attributes inside the block
      # @yield a block containing `attribute` calls
      # @return [void]
      def writeonly(**options, &block)
        with_access([:write], options, &block)
      end

      # Declares a group of required attributes.
      #
      # @param options [Hash] shared options for all attributes inside the block
      # @yield a block containing `attribute` calls
      # @return [void]
      def required(**options, &block)
        with_required(true, options, &block)
      end

      # Declares a group of optional attributes.
      #
      # @param options [Hash] shared options for all attributes inside the block
      # @yield a block containing `attribute` calls
      # @return [void]
      def optional(**options, &block)
        with_required(false, options, &block)
      end

      # Returns all non-transient attributes defined on the class.
      #
      # @return [Hash{Symbol => Castkit::Attribute}]
      def attributes
        @attributes ||= {}
      end

      # Alias for {#attribute}
      #
      # @see #attribute
      alias attr attribute

      # Alias for {#composite}
      #
      # @see #composite
      alias property composite

      private

      # Applies a reusable definition to the current attribute call.
      #
      # Ensures the declared type matches and merges options.
      #
      # @param field [Symbol] the attribute name
      # @param definition [Hash{Symbol => Object}, nil]
      # @param type [Symbol, Class]
      # @param options [Hash]
      # @return [Array<(Symbol, Hash)>] the final type and options
      # @raise [Castkit::DataObjectError] if type mismatch occurs
      def use_definition(field, definition, type, options)
        type ||= definition&.fetch(:type, nil)
        raise Castkit::AttributeError, "Attribute `#{field}  has no type" if type.nil?

        if definition && type != definition[:type]
          raise Castkit::AttributeError,
                "Attribute `#{field}` type mismatch: expected #{definition[:type].inspect}, got #{type.inspect}"
        end

        options = definition[:options].merge(options) if definition
        [type, build_options(options)]
      end

      # Instantiates and stores a Castkit::Attribute, defining accessors as needed.
      #
      # @param field [Symbol]
      # @param type [Symbol, Class]
      # @param options [Hash]
      # @return [void]
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

      # Defines a writer method that enforces type coercion.
      #
      # @param field [Symbol]
      # @param attribute [Castkit::Attribute]
      # @return [void]
      def define_typed_writer(field, attribute)
        define_method("#{field}=") do |value|
          deserialized_value = Castkit.type_caster(attribute.type.to_sym).call(
            value,
            options: attribute.options,
            context: attribute.field
          )

          instance_variable_set("@#{field}", deserialized_value)
        end
      end

      # Applies a temporary `access` context to all attributes within a block.
      #
      # @param access [Array<Symbol>] e.g. `[:read]` or `[:write]`
      # @param options [Hash]
      # @yield the block containing `attribute` calls
      # @return [void]
      def with_access(access, options = {}, &block)
        @__access_context = access
        @__block_options = options
        instance_eval(&block)
      ensure
        @__access_context = nil
        @__block_options = nil
      end

      # Applies a temporary `required` context to all attributes within a block.
      #
      # @param flag [Boolean]
      # @param options [Hash]
      # @yield the block containing `attribute` calls
      # @return [void]
      def with_required(flag, options = {}, &block)
        @__required_context = flag
        @__block_options = options
        instance_eval(&block)
      ensure
        @__required_context = nil
        @__block_options = nil
      end

      # Merges any current context flags (e.g., required, access) into the options hash.
      #
      # @param options [Hash]
      # @return [Hash] effective options for the attribute
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
