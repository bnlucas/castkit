# frozen_string_literal: true

require_relative "support/attribute"
require_relative "dsl/attribute"

module Castkit
  class Attribute
    include DSL::Attribute

    class << self
      def define(type, **options, &block)
        normalized_type = Support::Attribute.normalize_type(type)
        Attribute::Definition.define(normalized_type, **options, &block)
      end

      def from_definition(type = nil, definition)
        type ||= definition.type
        raise AttributeTypeMissing if type.nil?
        raise AttributeTypeMismatch if type != definition.type

        new(type, definition.options)
      end
    end

    def initialize(name, type, default: nil, **options)
      @name = name
      @type = Support::Attribute.normalize_type(type)
      @default = default
      @options = resolve_options(options)

      # validate!
    end

    def to_definition
      Attribute::Definition.new(type, )
    end

    def to_hash
      {
        name: @name,
        type: @type,
        default: @default,
        options: @options
      }
    end

    alias to_h to_hash

    private

    def resolve_options(options)
      options = DSL::Attributes::Options::DEFAULTS.merge(options)

      options[:aliases] = Array(options[:aliases]).compact
      options[:of] = Support::Attribute.normalize_type(options[:of]) if options[:of]

      options
    end
  end
end
