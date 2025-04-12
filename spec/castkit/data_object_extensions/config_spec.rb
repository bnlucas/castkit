# frozen_string_literal: true

require "spec_helper"
require "castkit/attribute"
require "castkit/data_object"
require "castkit/validator"
require "castkit/data_object_extensions/config"

RSpec.describe Castkit::DataObjectExtensions::Config do
  let(:klass) do
    Class.new do
      include Castkit::DataObjectExtensions::Config
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
      expect(klass.ignore_nil).to be true
    end
  end

  describe ".strict" do
    it "returns true by default (when unset)" do
      expect(klass.strict).to be true
    end

    it "sets strict to false and returns it" do
      klass.strict(false)
      expect(klass.strict).to be false
    end
  end

  describe ".ignore_unknown" do
    it "sets strict to false when called with true" do
      klass.ignore_unknown true
      expect(klass.strict).to be false
    end
  end

  describe ".warn_on_unknown" do
    it "returns nil by default" do
      expect(klass.warn_on_unknown).to be_nil
    end

    it "sets and returns the value" do
      klass.warn_on_unknown true
      expect(klass.warn_on_unknown).to be true
    end
  end

  describe ".relaxed" do
    it "creates a subclass with strict false and warn_on_unknown true by default" do
      relaxed_class = klass.relaxed
      expect(relaxed_class).not_to eq(klass)
      expect(relaxed_class.strict).to be false
      expect(relaxed_class.warn_on_unknown).to be true
    end

    it "allows overriding warn_on_unknown" do
      relaxed_class = klass.relaxed(warn_on_unknown: false)
      expect(relaxed_class.warn_on_unknown).to be false
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
      expect(instance.root_key_set?).to be false
    end

    it "returns true if root is set" do
      klass.root :meta
      expect(instance.root_key_set?).to be true
    end
  end
end
