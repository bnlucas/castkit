# frozen_string_literal: true

require "spec_helper"
require "castkit/attribute"
require "castkit/data_object"
require "castkit/validator"
require "castkit/attributes/definition"

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

    it "raises for symbol types that are not registered" do
      expect do
        described_class.new(:foo, :nope)
      end.to raise_error(Castkit::AttributeError)
    end
  end

  describe ".define" do
    it "builds reusable definitions" do
      definition = described_class.define(:string) { required false }
      expect(definition[:type]).to eq(:string)
      expect(definition[:options][:required]).to be(true)
    end
  end

  describe "#raise_error!" do
    it "raises a standardized attribute error" do
      attribute = described_class.new(:foo, :string)
      expect do
        attribute.send(:raise_error!, "boom")
      end.to raise_error(Castkit::AttributeError, /boom/)
    end
  end

  describe "option helpers" do
    let(:attribute) do
      dataobject_type = Class.new(Castkit::DataObject)
      described_class.new(:foo, dataobject_type, required: false, ignore_nil: true, ignore_blank: true,
                                                 composite: true, transient: true, unwrapped: true, prefix: nil)
    end

    it "exposes option predicates from DSL::Attribute::Options" do
      expect(attribute.required?).to be(false)
      expect(attribute.optional?).to be(true)
      expect(attribute.ignore_nil?).to be(true)
      expect(attribute.ignore_blank?).to be(true)
      expect(attribute.composite?).to be(true)
      expect(attribute.transient?).to be(true)
      expect(attribute.unwrapped?).to be(true)
      expect(attribute.prefix).to be_nil
    end
  end
end
