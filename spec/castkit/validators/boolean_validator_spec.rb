# frozen_string_literal: true

require "spec_helper"
require "castkit/validators/boolean_validator"

RSpec.describe Castkit::Validators::BooleanValidator do
  subject(:validator) { described_class.new }

  describe "#call" do
    it "returns true for truthy strings" do
      expect(validator.call("true", options: {}, context: :enabled)).to be(true)
    end

    it "returns true for actual booleans" do
      expect(validator.call(true, options: {}, context: :enabled)).to be(true)
    end

    it "returns false for falsy numeric strings" do
      expect(validator.call("0", options: {}, context: :enabled)).to be(false)
    end

    it "raises for unrecognized values" do
      expect do
        validator.call("maybe", options: {}, context: :enabled)
      end.to raise_error(Castkit::AttributeError, /enabled must be a boolean/)
    end
  end

  describe ".call" do
    it "instantiates and validates via class-level call" do
      expect(described_class.call("1", options: {}, context: :enabled)).to be(true)
    end
  end
end
