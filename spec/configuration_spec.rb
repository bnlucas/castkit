# frozen_string_literal: true

require "spec_helper"
require "castkit/configuration"
require "castkit/validators/string_validator"
require "castkit/validators/numeric_validator"

RSpec.describe Castkit::Configuration do
  subject(:config) { described_class.new }

  describe "default enforcement flags" do
    it "enables all enforcement flags by default" do
      expect(config.enforce_typing).to be true
      expect(config.enforce_attribute_access).to be true
      expect(config.enforce_unwrapped_prefix).to be true
      expect(config.enforce_array_options).to be true
    end
  end

  describe "#type_for" do
    it "returns built-in definitions for known types" do
      expect(config.fetch_type(:string)).to be_a(Castkit::Types::String)
      expect(config.fetch_type(:integer)).to be_a(Castkit::Types::Integer)
      expect(config.fetch_type(:float)).to be_a(Castkit::Types::Float)
    end

    it "raises when type is unknown and raise_type_errors is true" do
      config.raise_type_errors = true

      expect { config.fetch_type(:missing_type) }.to raise_error(Castkit::TypeError)
    end

    it "returns nil when type is unknown and raise_type_errors is false" do
      config.raise_type_errors = false

      expect(config.fetch_type(:missing_type)).to be_nil
    end
  end

  describe "#register_type" do
    let(:mock_definition) { Class.new(Castkit::Types::Base) }

    it "registers a new validator for a type" do
      config.register_type(:custom, mock_definition)
      expect(config.fetch_type(:custom)).to be_a(mock_definition)
    end

    it "registers aliases when provided" do
      config.register_type(:primary, mock_definition, aliases: [:alias_one])
      expect(config.fetch_type(:alias_one)).to be_a(mock_definition)
    end

    it "does not override existing validator by default" do
      original = config.fetch_type(:string)
      config.register_type(:string, mock_definition)
      expect(config.fetch_type(:string)).to eq(original)
    end

    it "overrides existing definition if override: true" do
      config.register_type(:string, mock_definition, override: true)
      expect(config.fetch_type(:string)).to be_a(mock_definition)
    end

    it "raises if definition is not a subclass of Castkit::Types::Base" do
      invalid = Class.new

      expect do
        config.register_type(:bad, invalid)
      end.to raise_error(Castkit::Error, /Expected subclass.*bad/)
    end
  end

  describe "#reset_typess!" do
    let(:mock_definition) { Class.new(Castkit::Types::Base) }

    it "resets to default types" do
      config.register_type(:string, mock_definition, override: true)
      expect(config.fetch_type(:string)).not_to be_a(Castkit::Types::String)

      config.reset_types!
      expect(config.fetch_type(:string)).to be_a(Castkit::Types::String)
    end
  end
end
