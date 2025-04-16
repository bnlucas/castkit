# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Contract::Validator do
  let(:attribute) do
    Castkit::Attribute.new(:id, :string)
  end

  let(:attributes) { [attribute] }

  describe ".call" do
    subject(:result) { described_class.call(attributes, input, **options) }

    context "with valid input" do
      let(:input) { { id: "abc" } }
      let(:options) { {} }

      it "returns no errors" do
        expect(result).to eq({})
      end
    end

    context "with invalid input type" do
      let(:input) { { id: 123 } }
      let(:options) { {} }

      it "returns type error for field" do
        expect(result).to include(:id)
        expect(result[:id]).to match(/must be a string/)
      end
    end

    context "with unknown attributes and strict mode" do
      let(:input) { { id: "abc", extra: "foo" } }
      let(:options) { { strict: true, allow_unknown: false } }

      it "returns an error for unknown attribute" do
        expect do
          described_class.call(attributes, input, **options)
        end.to raise_error(Castkit::ContractError, /Unknown attribute.*extra/)
      end
    end

    context "with nested dataobject" do
      let(:nested_class) do
        Class.new(Castkit::DataObject) do
          string :foo
        end
      end

      let(:attribute) { Castkit::Attribute.new(:nested, nested_class) }
      let(:attributes) { [attribute] }

      let(:input) { { nested: { foo: 123 } } }
      let(:options) { {} }

      it "recursively validates nested object" do
        expect(result[:nested]).to include(:foo)
        expect(result[:nested][:foo]).to match(/must be a string/)
      end
    end

    context "with nested array of dataobjects" do
      let(:item_class) do
        Class.new(Castkit::DataObject) do
          string :name
        end
      end

      let(:attribute) { Castkit::Attribute.new(:items, :array, of: item_class) }
      let(:attributes) { [attribute] }

      let(:input) { { items: [{ name: 123 }] } }
      let(:options) { {} }

      it "returns indexed errors for each item" do
        expect(result[:items]).to include(0)
        expect(result[:items][0]).to include(:name)
      end
    end
  end
end
