# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::DSL::DataObject::Deserialization do
  let(:klass) do
    Class.new do
      include Castkit::DSL::DataObject::Deserialization

      def self.attributes
        @attributes ||= {}
      end

      def self.add_attribute(field, attr)
        attributes[field] = attr
        attr_accessor field
      end

      def initialize(data = {})
        deserialize_attributes!(data)
      end
    end
  end

  describe ".from_hash / .from_h / .creator" do
    let(:attr) do
      double("Attribute",
             field: :foo,
             type: :string,
             skip_deserialization?: false,
             dataobject?: false,
             dataobject_collection?: false,
             key_path: [[:foo]])
    end

    before do
      klass.add_attribute(:foo, attr)
    end

    it "instantiates with symbolized keys" do
      instance = klass.from_hash("foo" => "bar")
      expect(instance.foo).to eq("bar")
    end
  end

  describe "#resolve_input_value" do
    let(:instance) { klass.new }
    let(:attribute) { double("Attribute", key_path: [%i[foo bar], [:alt]]) }

    it "returns the first matching value" do
      data = { foo: { bar: "found" } }
      expect(instance.send(:resolve_input_value, data, attribute)).to eq("found")
    end

    it "returns nil if no paths match" do
      data = {}
      expect(instance.send(:resolve_input_value, data, attribute)).to be_nil
    end
  end

  describe "#deserialize_attribute_value!" do
    let(:instance) { klass.new }

    it "uses default when value is nil" do
      attribute = Castkit::Attribute.new(:foo, :string, required: false, default: -> { "fallback" })
      expect(instance.send(:deserialize_attribute_value!, attribute, nil)).to eq("fallback")
    end

    it "raises when required and value is nil" do
      attribute = Castkit::Attribute.new(:foo, :string, required: true)
      expect do
        instance.send(:deserialize_attribute_value!, attribute, nil)
      end.to raise_error(Castkit::AttributeError)
    end
  end

  describe "#unwrap_prefixed_fields!" do
    let(:attribute) do
      double("Attribute",
             unwrapped?: true,
             prefix: "meta_",
             field: :meta,
             skip_deserialization?: true)
    end
    let(:instance) { klass.new }

    before do
      allow(klass).to receive(:attributes).and_return(meta: attribute)
    end

    it "moves prefixed fields into a nested hash and deletes originals" do
      data = {
        meta_name: "Alice",
        meta_age: 30,
        keep: "yes"
      }

      result = instance.send(:unwrap_prefixed_fields!, data.dup)

      expect(result[:meta]).to eq(name: "Alice", age: 30)
      expect(result).to include(:keep)
      expect(result).not_to include(:meta_name, :meta_age)
    end
  end

  describe "#unwrap_prefixed_values" do
    let(:attribute) { double("Attribute", prefix: "x_") }
    let(:instance) { klass.new }

    it "returns stripped keys and keys to remove" do
      data = { "x_foo" => 1, "x_bar" => 2, "other" => 3 }

      unwrapped, removed = instance.send(:unwrap_prefixed_values, data, attribute)

      expect(unwrapped).to eq(foo: 1, bar: 2)
      expect(removed).to contain_exactly("x_foo", "x_bar")
    end
  end
end
