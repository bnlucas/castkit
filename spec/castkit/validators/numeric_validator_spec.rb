# frozen_string_literal: true

require "spec_helper"
require "castkit/validators/numeric_validator"

RSpec.describe Castkit::Validators::NumericValidator do
  subject(:validator) { described_class.new }

  describe "#call" do
    context "when value is below min" do
      let(:options) { { min: 10 } }

      it "raises an error" do
        expect do
          validator.call(5, options: options, context: :price)
        end.to raise_error(Castkit::AttributeError, /price must be >= 10/)
      end
    end

    context "when value is above max" do
      let(:options) { { max: 100 } }

      it "raises an error" do
        expect do
          validator.call(150, options: options, context: :price)
        end.to raise_error(Castkit::AttributeError, /price must be <= 100/)
      end
    end

    context "when value is within bounds" do
      let(:options) { { min: 10, max: 100 } }

      it "does not raise an error" do
        expect do
          validator.call(50, options: options, context: :price)
        end.not_to raise_error
      end
    end

    context "when no bounds are given" do
      it "does not raise an error" do
        expect do
          validator.call(42, options: {}, context: :score)
        end.not_to raise_error
      end
    end
  end
end
