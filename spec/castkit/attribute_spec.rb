# frozen_string_literal: true

require "spec_helper"
require "castkit/attribute"
require "castkit/data_object"
require "castkit/validator"

RSpec.describe Castkit::Attribute do
  subject(:instance) { described_class.new(:foo, type, **options) }

  let(:options) { {} }
  let(:type) { :string }

  describe "#initialize" do
    it "sets field, type, default, and options" do
      instance = described_class.new(:foo, String, default: "bar")
      expect(instance.field).to eq(:foo)
      expect(instance.type).to eq(:string)
      expect(instance.options[:required]).to eq(true)
      expect(instance.to_h[:default]).to eq("bar")
    end

    it "normalizes boolean types" do
      instance = described_class.new(:flag, TrueClass)
      expect(instance.type).to eq(:boolean)
    end

    it "normalizes aliases" do
      instance = described_class.new(:foo, String, aliases: "foo.bar")
      expect(instance.options[:aliases]).to eq(["foo.bar"])
    end

    it "normalizes :of option if present" do
      instance = described_class.new(:foo, :array, of: String)
      expect(instance.options[:of]).to eq(:string)
    end
  end

  describe "#to_h" do
    it "returns correct hash structure" do
      expect(instance.to_h).to include(:field, :type, :options, :default)
    end
  end

  describe "#normalize_type" do
    it "returns :string for String class" do
      attr = described_class.new(:foo, String)
      expect(attr.type).to eq(:string)
    end

    it "normalizes array of types" do
      attr = described_class.new(:foo, [String, Integer])
      expect(attr.type).to eq(%i[string integer])
    end

    it "returns :boolean for TrueClass/FalseClass" do
      attr = described_class.new(:flag, TrueClass)
      expect(attr.type).to eq(:boolean)
    end

    it "raises for unknown types" do
      expect do
        described_class.new(:foo, Object.new)
      end.to raise_error(Castkit::AttributeError)
    end
  end
end
