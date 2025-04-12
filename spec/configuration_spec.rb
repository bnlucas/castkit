# frozen_string_literal: true

require "spec_helper"
require "castkit/configuration"
require "castkit/validators/string_validator"
require "castkit/validators/numeric_validator"

RSpec.describe Castkit::Configuration do
  subject(:config) { described_class.new }

  describe "default enforcement flags" do
    it "enables all enforcement flags by default" do
      expect(config.enforce_array_of_type).to be true
      expect(config.enforce_known_primitive_type).to be true
      expect(config.enforce_boolean_casting).to be true
      expect(config.enforce_union_match).to be true
      expect(config.enforce_attribute_access).to be true
      expect(config.enforce_unwrapped_prefix).to be true
      expect(config.enforce_array_options).to be true
    end
  end

  describe "#validator_for" do
    it "returns built-in validators for known types" do
      expect(config.validator_for(:string)).to eq(Castkit::Validators::StringValidator)
      expect(config.validator_for(:integer)).to eq(Castkit::Validators::NumericValidator)
      expect(config.validator_for(:float)).to eq(Castkit::Validators::NumericValidator)
    end
  end

  describe "#register_validator" do
    let(:mock_validator) do
      Class.new do
        def self.call(_value, _options:, _context:)
          true
        end
      end
    end

    it "registers a new validator for a type" do
      config.register_validator(:custom, mock_validator)
      expect(config.validator_for(:custom)).to eq(mock_validator)
    end

    it "does not override existing validator by default" do
      original = config.validator_for(:string)
      config.register_validator(:string, mock_validator)
      expect(config.validator_for(:string)).to eq(original)
    end

    it "overrides existing validator if override: true" do
      config.register_validator(:string, mock_validator, override: true)
      expect(config.validator_for(:string)).to eq(mock_validator)
    end

    it "raises if validator does not respond to `.call`" do
      invalid = Class.new

      expect do
        config.register_validator(:bad, invalid)
      end.to raise_error(Castkit::Error, /must respond to `.call/)
    end
  end

  describe "#reset_validators!" do
    it "resets to default validators" do
      config.register_validator(:string, ->(*) {}, override: true)
      expect(config.validator_for(:string)).not_to eq(Castkit::Validators::StringValidator)

      config.reset_validators!
      expect(config.validator_for(:string)).to eq(Castkit::Validators::StringValidator)
    end
  end
end
