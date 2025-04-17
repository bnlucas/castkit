# frozen_string_literal: true

require "spec_helper"
require "castkit/serializers/default_serializer"

RSpec.describe Castkit::Serializers::DefaultSerializer do
  let(:attribute) do
    double("Attribute",
           field: :name,
           type: :string,
           skip_serialization?: false,
           ignore_nil?: false,
           ignore_blank?: false,
           dataobject?: false,
           dataobject_collection?: false,
           key_path: [:name],
           dump: "Tester")
  end

  let(:klass) do
    attr = attribute
    Class.new do
      define_method(:name) { "Tester" }

      define_singleton_method(:attributes) { { test: attr } }
      define_singleton_method(:root) { nil }
      define_singleton_method(:allow_unknown) { false }
      define_singleton_method(:ignore_nil) { false }
      define_singleton_method(:ignore_blank) { false }

      define_method(:unknown_attributes) { {} }
    end
  end

  let(:obj) { klass.new }

  describe ".call" do
    it "serializes the object using default rules" do
      result = described_class.call(obj)
      expect(result).to eq({ name: "Tester" })
    end
  end

  describe "#call" do
    it "wraps in root if root is set" do
      allow(klass).to receive(:root).and_return("user")

      serializer = described_class.new(obj)
      expect(serializer.call).to eq({ user: { name: "Tester" } })
    end

    it "does not wrap if root is nil" do
      serializer = described_class.new(obj)
      expect(serializer.call).to eq({ name: "Tester" })
    end

    it "includes unknown attributes when `allow_unknown` is true and `unknown_attributes` is populated" do
      allow(klass).to receive(:allow_unknown).and_return(true)
      allow(obj).to receive(:unknown_attributes).and_return({ unknown: "key" })

      serializer = described_class.new(obj)
      expect(serializer.call).to eq({ name: "Tester", unknown: "key" })
    end
  end

  describe "#serialize_attributes" do
    it "skips attribute if skip_serialization? is true" do
      allow(attribute).to receive(:skip_serialization?).and_return(true)

      result = described_class.new(obj).send(:serialize_attributes)
      expect(result).to eq({})
    end

    it "skips if value is nil and ignore_nil is true" do
      allow(attribute).to receive(:ignore_nil?).and_return(true)
      allow(obj).to receive(:name).and_return(nil)
      allow(attribute).to receive(:dump).and_return(nil)

      result = described_class.new(obj).send(:serialize_attributes)
      expect(result).to eq({})
    end

    it "skips if value is blank and ignore_blank is true" do
      allow(attribute).to receive(:ignore_blank?).and_return(true)
      allow(attribute).to receive(:dump).and_return([])
      allow(obj).to receive(:name).and_return(nil)

      result = described_class.new(obj).send(:serialize_attributes)
      expect(result).to eq({})
    end

    it "adds attribute to hash with key path" do
      allow(attribute).to receive(:key_path).and_return(%i[profile first])
      allow(attribute).to receive(:dump).and_return("Tester")

      result = described_class.new(obj).send(:serialize_attributes)
      expect(result).to eq({ profile: { first: "Tester" } })
    end
  end

  describe "#assign_attribute_key!" do
    it "sets deeply nested value from key path" do
      attribute = double("Attribute", key_path: %i[a b c])
      hash = {}
      described_class.new(obj).send(:assign_attribute_key!, attribute, 42, hash)
      expect(hash).to eq({ a: { b: { c: 42 } } })
    end
  end

  describe "#blank?" do
    let(:serializer) { described_class.new(obj) }

    it "returns true for nil" do
      expect(serializer.send(:blank?, nil)).to be true
    end

    it "returns true for empty array" do
      expect(serializer.send(:blank?, [])).to be true
    end

    it "returns false for non-empty string" do
      expect(serializer.send(:blank?, "hi")).to be false
    end
  end
end
