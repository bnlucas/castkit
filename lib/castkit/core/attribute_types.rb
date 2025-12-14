# frozen_string_literal: true

module Castkit
  module Core
    # Provides DSL methods to define typed attributes in a Castkit::DataObject.
    #
    # These helpers are shortcuts for calling `attribute` with a specific type.
    module AttributeTypes
      # Inclusion hook: ensures config is loaded and extends the including class with DSL
      def self.included(base)
        Castkit.configuration # triggers type/alias registration
        base.extend(self)
      end

      class << self
        # Dynamically defines a DSL method for a registered type.
        #
        # @param type [Symbol] the name of the type
        # @return [void]
        def define_type_dsl(type)
          AttributeTypes.module_eval do
            define_method(type) do |field, **options|
              attribute(field, type.to_sym, **options)
            end
          end
        end
      end

      # Defines a string attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def string(field, **options)
        attribute(field, :string, **options)
      end

      # Defines an integer attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def integer(field, **options)
        attribute(field, :integer, **options)
      end

      # Defines a boolean attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def boolean(field, **options)
        attribute(field, :boolean, **options)
      end

      # Defines a float attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def float(field, **options)
        attribute(field, :float, **options)
      end

      # Defines a date attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def date(field, **options)
        attribute(field, :date, **options)
      end

      # Defines a datetime attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def datetime(field, **options)
        attribute(field, :datetime, **options)
      end

      # Defines an array attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def array(field, **options)
        attribute(field, :array, **options)
      end

      # Defines a hash attribute.
      #
      # @param field [Symbol]
      # @param options [Hash]
      def hash(field = nil, **options)
        return super() if field.nil?

        attribute(field, :hash, **options)
      end

      # Defines a nested Castkit::DataObject attribute.
      #
      # @param field [Symbol]
      # @param type [Class<Castkit::DataObject>]
      # @param options [Hash]
      # @raise [Castkit::AttributeError] if type is not a subclass of Castkit::DataObject
      def dataobject(field, type, **options)
        unless type < Castkit::DataObject
          raise Castkit::AttributeError, "Data objects must extend from Castkit::DataObject"
        end

        attribute(field, type, **options)
      end

      # Defines an unwrapped nested Castkit::DataObject attribute.
      #
      # All keys from this object will be flattened with an optional prefix.
      #
      # @param field [Symbol]
      # @param type [Class<Castkit::DataObject>]
      # @param options [Hash]
      def unwrapped(field, type, **options)
        attribute(field, type, **options, unwrapped: true)
      end

      # Alias for `dataobject`
      alias dto dataobject
    end
  end
end
