# frozen_string_literal: true

module Castkit
  module AttributeExtensions
    # Provides access control helpers for attributes.
    #
    # These helpers determine whether an attribute is readable, writeable,
    # or should be included during serialization/deserialization based on the
    # configured `:access` and `:ignore` options.
    module Access
      # Returns the normalized access modes for the attribute (e.g., [:read, :write]).
      #
      # @return [Array<Symbol>] list of access symbols
      def access
        Array(options[:access]).map(&:to_sym)
      end

      # Whether the attribute should be included during serialization.
      #
      # @return [Boolean]
      def readable?
        access.include?(:read)
      end

      # Whether the attribute should be accepted during deserialization.
      #
      # Composite attributes are excluded from writeability.
      #
      # @return [Boolean]
      def writeable?
        access.include?(:write) && !composite?
      end

      # Whether the attribute is both readable and writeable.
      #
      # @return [Boolean]
      def full_access?
        readable? && writeable?
      end

      # Whether the attribute should be skipped during serialization.
      #
      # This is true if it's not readable or is marked as ignored.
      #
      # @return [Boolean]
      def skip_serialization?
        !readable? || ignore?
      end

      # Whether the attribute should be skipped during deserialization.
      #
      # @return [Boolean]
      def skip_deserialization?
        !writeable?
      end

      # Whether the attribute is ignored completely.
      #
      # @return [Boolean]
      def ignore?
        options[:ignore]
      end
    end
  end
end
