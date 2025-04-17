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
  end
end
