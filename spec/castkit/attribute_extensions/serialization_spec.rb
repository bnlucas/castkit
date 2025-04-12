# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"
require "castkit/attribute_extensions/options"
require "castkit/attribute_extensions/casting"
require "castkit/attribute_extensions/serialization"

RSpec.describe Castkit::AttributeExtensions::Serialization do
  let(:dummy_class) do
    Class.new do
      include Castkit::AttributeExtensions::Options
      include Castkit::AttributeExtensions::Casting
      include Castkit::AttributeExtensions::Serialization

      attr_accessor :field, :type, :options, :default

      def initialize(field, type, default: nil, **options)
        @field = field
        @type = type
        @default = default
        @options = options
      end

      def required?
        options[:required]
      end

      def validate_value!(value, context:)
        # stub
      end

      def raise_error!(msg)
        raise Castkit::AttributeError, msg
      end
    end
  end

  subject(:instance) { dummy_class.new(:foo, type, **options) }
  let(:options) { { required: true } }
  let(:type) { :string }

  describe "#load" do
    context "when value is nil and optional" do
      let(:options) { { default: "bar", required: false } }

      it "returns default" do
        expect(instance.load(nil, context: :foo)).to eq("bar")
      end
    end

    context "when required and value is nil" do
      let(:options) { { required: true } }

      it "raises an error" do
        expect do
          instance.load(nil, context: :foo)
        end.to raise_error(Castkit::AttributeError)
      end
    end

    context "when value is castable" do
      it "casts and validates the value" do
        expect(instance.load(123, context: :foo)).to eq("123")
      end
    end
  end

  describe "#dump" do
    let(:hashable_object) do
      Class.new do
        def to_h(_visited = nil)
          { key: "value" }
        end
      end.new
    end

    it "returns nil if value is nil" do
      expect(instance.dump(nil)).to be_nil
    end

    it "calls to_h on hashable values" do
      expect(instance.dump(hashable_object, visited: Set.new)).to eq({ key: "value" })
    end

    it "returns value if primitive" do
      expect(instance.dump("x")).to eq("x")
    end
  end

  describe "#dump_element" do
    # let(:instance) { dummy_class.new(options: {}) }

    it "returns value if nil" do
      expect(instance.send(:dump_element, nil)).to be_nil
    end

    it "returns value if primitive" do
      expect(instance.send(:dump_element, 123)).to eq(123)
    end

    it "calls serializer if value is a Castkit::DataObject" do
      klass = Class.new(Castkit::DataObject) do
        string :name, default: "TestDataObject"
      end

      expected = { name: "TestDataObject" }
      object = klass.new
      instance = dummy_class.new(:foo, :object)

      result = instance.send(:dump_element, object)
      expect(result).to eq(expected)
    end

    it "calls to_h if value is hashable" do
      class HashableThing
        def to_h(*)
          { key: "val" }
        end
      end

      instance = dummy_class.new(:foo, :object)
      value = HashableThing.new

      expect(instance.send(:dump_element, value)).to eq({ key: "val" })
    end
  end

  describe "#hashable?" do
    it "returns true for non-primitive objects with to_h" do
      obj = double("Hashable", to_h: {}, is_a?: false)
      expect(instance.send(:hashable?, obj)).to be true
    end

    it "returns false for primitive values" do
      expect(instance.send(:hashable?, "str")).to be false
    end
  end

  describe "#primitive?" do
    it "returns true for string, symbol, numeric, boolean" do
      expect(instance.send(:primitive?, "hi")).to be true
      expect(instance.send(:primitive?, :sym)).to be true
      expect(instance.send(:primitive?, 1)).to be true
      expect(instance.send(:primitive?, true)).to be true
      expect(instance.send(:primitive?, false)).to be true
    end

    it "returns false for other objects" do
      expect(instance.send(:primitive?, Object.new)).to be false
    end
  end
end
