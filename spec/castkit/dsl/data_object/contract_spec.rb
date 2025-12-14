# frozen_string_literal: true

require "spec_helper"
require "castkit/dsl/data_object/contract"

RSpec.describe Castkit::DSL::DataObject::Contract do
  let(:dataobject_class) do
    Class.new(Castkit::DataObject) do
      string :id
      integer :age, required: false
    end
  end

  describe ".contract" do
    it "memoizes the contract" do
      first = dataobject_class.contract
      expect(dataobject_class.contract).to equal(first)
    end
  end

  describe ".from_contract" do
    it "rebuilds a DataObject class from a contract" do
      contract = dataobject_class.contract
      rebuilt = Castkit::DataObject.from_contract(contract)

      instance = rebuilt.new(id: "x")
      expect(instance.id).to eq("x")
      expect(instance).to respond_to(:age=)
      expect(rebuilt.attributes.keys).to include(:id, :age)
    end

    it "validates data via the rebuilt contract helpers" do
      contract = dataobject_class.contract
      rebuilt = Castkit::DataObject.from_contract(contract)

      expect(rebuilt.validate(id: "ok").success?).to be(true)
      expect { rebuilt.validate!(id: 1) }.to raise_error(Castkit::ContractError)
    end
  end
end
