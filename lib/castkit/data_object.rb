# frozen_string_literal: true

require "set"
require_relative "dsl/abstract_class"

module Castkit
  class DataObjects < Castkit::DSL::AbstractClass
    cattr :contract, default: -> { to_contract }
    cattr :root do
      ->(value) { value.to_s.strip.to_sym }
    end
    cattr :ignore_nil, default: false
    cattr :ignore_blank, default: false
    cattr :enabled_plugins, default: Set.new
    cattr :disabled_plugins, default: Set.new
    cattr :serializer do |klass|
      raise Castkit::SerializerInheritanceError unless klass < Castkit::Serializers::Base

      klass
    end
    cattr :__raw, default: {} do |data|
      data.dup.freeze
    end
    cattr :unknown_attributes, default: {} do |data|
      data.reject { |k, _v| k == attributes.key?(k.to_sym) }.freeze
    end

    # @param value [Boolean]
    # @return [Boolean]
    define_proxy :tester

    def define_proxy(method)
      define_singleton_method(name) do |value = nil|
        definition.public_send(name, value)
      end
    end
  end
end

class Test < DataObject
  tester true
end
