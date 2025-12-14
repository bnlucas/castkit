# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Contract do
  describe ".build" do
    let(:contract) do
      Castkit::Contract.build do
        string :id
        string :name, required: false
      end
    end

    it "returns Result from validate" do
      result = contract.validate(id: "123", name: "Castkit")

      expect(result).to be_a(Castkit::Contract::Result)
    end

    it "builds a contract and validates successfully" do
      result = contract.validate(id: "123", name: "Castkit")

      expect(result).to be_success
      expect(result.input).to eq(id: "123", name: "Castkit")
    end

    it "fails validation when type is incorrect" do
      result = contract.validate(id: 123)

      expect(result).to be_failure
      expect(result.errors).to include(id: /id must be a string/)
    end

    it "respects optional fields" do
      result = contract.validate(id: "123")

      expect(result).to be_success
      expect(result.input).to eq(id: "123")
    end

    it "raises ContractError with validate!" do
      expect { contract.validate!(id: 123) }.to raise_error(Castkit::ContractError)
    end

    it "accepts a custom contract name" do
      contract_name = :user_input
      contract = Castkit::Contract.build(contract_name) do
        string :id
        string :name, required: false
      end

      result = contract.validate(id: "123", name: "Castkit")

      expect(result).to be_success
      expect(result.contract).to eq(contract_name)
    end

    it "stores definition via class-level Cattri" do
      contract = Castkit::Contract.build(:cattri_contract) do
        string :id
      end

      expect(contract.definition[:name]).to eq(:cattri_contract)
      expect(contract.definition[:attributes].keys).to include(:id)
    end

    it "raises when source is not a DataObject or block" do
      klass = Class.new(Castkit::Contract::Base)
      expect do
        klass.send(:define, :bad, "not a dataobject")
      end.to raise_error(Castkit::ContractError, /Expected a Castkit::DataObject/)
    end

    it "raises when both source and block are provided" do
      dataobject = Class.new(Castkit::DataObject) { attribute :id, :string }
      klass = Class.new(Castkit::Contract::Base)

      expect do
        klass.send(:define, :bad, dataobject) { string :id }
      end.to raise_error(Castkit::ContractError, /both source and block/)
    end
  end

  describe "base definition" do
    it "exposes the default definition cached by Cattri" do
      definition = Castkit::Contract::Base.definition

      expect(definition[:name]).to eq(:ephemeral)
      expect(definition[:attributes]).to eq({})
    end
  end

  describe Castkit::Contract::Result do
    it "renders a success string when there are no errors" do
      result = described_class.new(:sample, {}, errors: {})
      expect(result.to_s).to include("passed")
    end

    it "renders a failure string with parsed errors" do
      result = described_class.new(:sample, {}, errors: { foo: "bar" })
      expect(result.to_s).to include("failed")
      expect(result.to_s).to include("foo")
      expect(result.to_hash[:errors]).to eq({ foo: "bar" })
      expect(result.inspect).to include("success=false")
    end
  end
end
