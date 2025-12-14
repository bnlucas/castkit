# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Core::Config do
  let(:klass) do
    Class.new do
      extend Castkit::Core::Config
    end
  end

  describe ".strict" do
    it "returns true by default (when unset)" do
      expect(klass.strict).to be(true)
    end

    it "sets strict to false and returns it" do
      klass.strict(false)
      expect(klass.strict).to be(false)
    end
  end

  describe ".ignore_unknown" do
    it "sets strict to false when called with true" do
      klass.ignore_unknown true
      expect(klass.strict).to be(false)
    end
  end

  describe ".warn_on_unknown" do
    it "returns nil by default" do
      expect(klass.warn_on_unknown).to be_nil
    end

    it "sets and returns the value" do
      klass.warn_on_unknown true
      expect(klass.warn_on_unknown).to be(true)
    end
  end

  describe ".allow_unknown" do
    it "returns nil by default" do
      expect(klass.allow_unknown).to be_nil
    end

    it "sets and returns the value" do
      klass.allow_unknown true
      expect(klass.allow_unknown).to be(true)
    end
  end

  describe ".relaxed" do
    it "creates a subclass with strict false and warn_on_unknown true by default" do
      relaxed_class = klass.relaxed
      expect(relaxed_class).not_to eq(klass)
      expect(relaxed_class.strict).to be(false)
      expect(relaxed_class.warn_on_unknown).to be(true)
    end

    it "allows overriding warn_on_unknown" do
      relaxed_class = klass.relaxed(warn_on_unknown: false)
      expect(relaxed_class.warn_on_unknown).to be(false)
    end

    it "rebuilds validation rules via cattri-backed flags" do
      relaxed_class = klass.relaxed
      expect(relaxed_class.validation_rules).to include(:strict, :allow_unknown, :warn_on_unknown)
    end
  end
end
