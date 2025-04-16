# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Ext::DataObject::Serialization do
  let(:klass) do
    Class.new do
      include Castkit::Ext::DataObject::Serialization
    end
  end

  describe ".root" do
    it "returns nil by default" do
      expect(klass.root).to be_nil
    end

    it "sets and returns root value as string" do
      klass.root :user
      expect(klass.root).to eq(:user)
    end
  end

  describe ".ignore_nil" do
    it "returns nil by default" do
      expect(klass.ignore_nil).to be_nil
    end

    it "sets and returns ignore_nil value" do
      klass.ignore_nil true
      expect(klass.ignore_nil).to be(true)
    end
  end

  describe "#root_key" do
    let(:instance) { klass.new }

    it "returns the symbolized root key" do
      klass.root :data
      expect(instance.root_key).to eq(:data)
    end
  end

  describe "#root_key_set?" do
    let(:instance) { klass.new }

    it "returns false if root not set" do
      expect(instance.root_key_set?).to be(false)
    end

    it "returns true if root is set" do
      klass.root :meta
      expect(instance.root_key_set?).to be(true)
    end
  end
end
