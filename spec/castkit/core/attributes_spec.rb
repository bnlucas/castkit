# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Core::Attributes do
  let(:klass) do
    Class.new do
      extend Castkit::Core::Attributes
    end
  end

  describe ".attribute" do
    it "defines a writable attribute by default" do
      klass.attribute :name, :string

      instance = klass.new
      instance.name = "foo"

      expect(instance.name).to eq("foo")
    end

    it "raises an error if attribute is already defined" do
      klass.attribute :duplicate, :string

      expect do
        klass.attribute :duplicate, :string
      end.to raise_error(Castkit::DataObjectError, /already defined/)
    end

    it "defines a transient attribute without tracking it" do
      klass.attribute :temp, :string, transient: true

      instance = klass.new
      instance.temp = "bar"

      expect(instance.temp).to eq("bar")
      expect(klass.attributes).not_to have_key(:temp)
    end
  end

  describe ".composite" do
    it "defines a composite attribute with a method" do
      klass.composite(:title, :string) { "computed" }

      instance = klass.new

      expect(instance.title).to eq("computed")
    end
  end

  describe ".transient" do
    it "marks all attributes inside block as transient" do
      klass.transient do
        attribute :temp1, :string
        attribute :temp2, :string
      end

      instance = klass.new
      instance.temp1 = "val1"
      instance.temp2 = "val2"

      expect(instance.temp1).to eq("val1")
      expect(instance.temp2).to eq("val2")
      expect(klass.attributes.keys).not_to include(:temp1, :temp2)
    end
  end

  describe ".readonly" do
    it "only defines reader methods" do
      klass.readonly { attribute :read_only, :string }

      instance = klass.new
      expect(instance).to respond_to(:read_only)
      expect(instance).not_to respond_to(:read_only=)
    end
  end

  describe ".writeonly" do
    it "only defines writer methods" do
      klass.writeonly { attribute :write_only, :string }

      instance = klass.new
      expect(instance).not_to respond_to(:write_only)
      expect(instance).to respond_to(:write_only=)
    end
  end

  describe ".required and .optional" do
    it "marks attributes as required or optional" do
      klass.required { attribute :must_have, :string }
      klass.optional { attribute :may_have, :string }

      expect(klass.attributes[:must_have].required?).to be true
      expect(klass.attributes[:may_have].required?).to be false
    end
  end

  describe ".property and aliases" do
    it "defines a property as an alias to composite" do
      klass.property(:thing, :string) { "alias_works" }

      instance = klass.new
      expect(instance.thing).to eq("alias_works")
    end
  end
end
