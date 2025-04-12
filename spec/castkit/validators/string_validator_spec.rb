# frozen_string_literal: true

require "spec_helper"
require "castkit/validators/string_validator"

RSpec.describe Castkit::Validators::StringValidator do
  subject(:validator) { described_class.new }

  describe "#call" do
    context "when no format is provided" do
      context "when no format is provided" do
        it "passes for String values" do
          expect do
            validator.call("hello", options: {}, context: :name)
          end.not_to raise_error
        end

        it "raises if value is not a String" do
          expect do
            validator.call(123, options: {}, context: :name)
          end.to raise_error(Castkit::AttributeError, /name must be a String/)
        end
      end
    end

    context "when format is a Regexp" do
      let(:options) { { format: /^abc/ } }

      it "raises an error if value doesn't match" do
        expect do
          validator.call("def", options: options, context: :code)
        end.to raise_error(Castkit::AttributeError, /code must match format/)
      end

      it "passes if value matches" do
        expect do
          validator.call("abc123", options: options, context: :code)
        end.not_to raise_error
      end
    end

    context "when format is a Proc" do
      let(:options) { { format: ->(v) { v.include?("@") } } }

      it "raises an error if Proc returns false" do
        expect do
          validator.call("no-at-symbol", options: options, context: :email)
        end.to raise_error(Castkit::AttributeError, /email failed format validation/)
      end

      it "passes if Proc returns true" do
        expect do
          validator.call("test@example.com", options: options, context: :email)
        end.not_to raise_error
      end
    end

    context "when format is an unsupported type" do
      let(:options) { { format: 123 } }

      it "raises an error" do
        expect do
          validator.call("value", options: options, context: :thing)
        end.to raise_error(Castkit::AttributeError, /thing has unsupported format validator: Integer/)
      end
    end
  end
end
