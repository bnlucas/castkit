# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"

RSpec.describe Castkit::DataObject do
  let(:subclass) do
    Class.new(described_class) do
      attribute :name, :string
      attribute :age, :integer, aliases: [:years_old]

      def self.name
        "TestObject"
      end
    end
  end

  let(:valid_input) { { name: "Tester", age: 30 } }

  before do
    allow(Castkit).to receive(:warning)
  end

  describe ".cast" do
    it "returns the object if it's already an instance" do
      instance = subclass.new(valid_input)
      expect(subclass.cast(instance)).to be(instance)
    end

    it "casts from hash" do
      expect(subclass.cast(valid_input)).to be_a(subclass)
    end

    it "raises for unsupported types" do
      expect { subclass.cast("oops") }.to raise_error(Castkit::DataObjectError)
    end
  end

  describe ".serializer" do
    it "gets and sets a custom serializer" do
      custom_serializer = Class.new(Castkit::Serializer)
      subclass.serializer(custom_serializer)
      expect(subclass.serializer).to eq(custom_serializer)
    end

    it "raises if serializer is not a Castkit::Serializer" do
      expect do
        subclass.serializer(Class.new)
      end.to raise_error(ArgumentError, /must inherit from Castkit::Serializer/)
    end
  end

  describe ".dump" do
    it "delegates to_json on the object" do
      instance = subclass.new(valid_input)
      expect(JSON.parse(subclass.dump(instance))).to eq({ "name" => "Tester", "age" => 30 })
    end
  end

  describe "#initialize" do
    it "instantiates with valid fields" do
      instance = subclass.new(valid_input)
      expect(instance.name).to eq("Tester")
      expect(instance.age).to eq(30)
    end

    it "unwraps root if configured" do
      subclass.root :person
      input = { person: { name: "Wrapped", age: 20 } }

      instance = subclass.new(input)
      expect(instance.name).to eq("Wrapped")
    end

    it "raises on unknown keys in strict mode" do
      subclass.strict true
      expect do
        subclass.new(valid_input.merge(extra: 1))
      end.to raise_error(Castkit::DataObjectError, /Unknown attribute/)
    end

    it "raises on unknown keys in strict mode when allow_unknown is also false" do
      subclass.strict true
      subclass.allow_unknown false

      expect do
        subclass.new(valid_input.merge(extra: 1))
      end.to raise_error(Castkit::DataObjectError, /Unknown attribute/)
    end

    it "warns on unknown keys in warn mode" do
      subclass.strict false
      subclass.warn_on_unknown true

      subclass.new(valid_input.merge(foo: 1))
      expect(Castkit).to have_received(:warning).with(/Unknown attribute.*foo/)
    end

    it "warns when strict is set to true and allow_unknown is set to true" do
      subclass.strict true
      subclass.allow_unknown true
      subclass.new(valid_input)

      expect(Castkit).to have_received(:warning).with(/`strict` and `allow_unknown` are enabled/)
    end

    it "overrides strict when allow_unknown is true" do
      subclass.strict true
      subclass.allow_unknown true

      expect { subclass.new(valid_input.merge(extra: 1)) }.not_to raise_error
    end
  end

  describe "#__raw" do
    it "returns the raw data on instantiation" do
      subclass.root :person
      input = { person: { name: "Wrapped", age: 20 } }

      instance = subclass.new(input)
      expect(instance.__raw).to eq(input)
    end
  end

  describe "#unknown_attributes" do
    it "returns undefined (unknown) attributes" do
      subclass.allow_unknown true

      instance = subclass.new(valid_input.merge(extra: 1))
      expect(instance.unknown_attributes).to eq({ extra: 1 })
    end
  end

  describe "#to_hash / #serialize / #to_h" do
    it "returns the serialized hash via default serializer" do
      instance = subclass.new(valid_input)
      expect(instance.to_hash).to eq({ name: "Tester", age: 30 })
      expect(instance.serialize).to eq(instance.to_hash)
    end

    it "returns the serialized hash with unknown attributes" do
      subclass.allow_unknown true

      instance = subclass.new(valid_input.merge(extra: 1))
      expect(instance.to_hash).to eq({ name: "Tester", age: 30, extra: 1 })
    end
  end

  describe "#to_json" do
    it "returns the serialized JSON string" do
      instance = subclass.new(valid_input)
      json = instance.to_json
      expect(JSON.parse(json)).to eq({ "name" => "Tester", "age" => 30 })
    end
  end
end
