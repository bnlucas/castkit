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
      expect(JSON.parse(subclass.dump(instance))).to eq({
                                                          "name" => "Tester",
                                                          "age" => 30
                                                        })
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

    it "warns on unknown keys in warn mode" do
      subclass.strict false
      subclass.warn_on_unknown true

      expect do
        subclass.new(valid_input.merge(foo: 1))
      end.to output(/Unknown attribute.*foo/).to_stderr
    end
  end

  describe "#to_hash / #serialize / #to_h" do
    it "returns the serialized hash via default serializer" do
      instance = subclass.new(valid_input)
      expect(instance.to_hash).to eq({ name: "Tester", age: 30 })
      expect(instance.serialize).to eq(instance.to_hash)
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
