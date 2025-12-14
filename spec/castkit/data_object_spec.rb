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

  describe ".contract" do
    let(:klass) do
      Class.new(described_class) do
        string :id
        string :email, required: false
      end
    end

    it "builds a contract with the class name as the default" do
      contract = klass.contract

      expect(contract.attributes.keys).to contain_exactly(:id, :email)
      expect(contract.attributes[:id].required?).to eq(true)
      expect(contract.attributes[:email].required?).to eq(false)
    end

    it "returns a contract that validates like the original DataObject" do
      contract = klass.contract

      expect do
        contract.validate!(id: 123)
      rescue Castkit::ContractError => e
        expect(e.errors).to include(id: /id must be a string/)
        raise e
      end.to raise_error(Castkit::ContractError)

      result = contract.validate(id: "abc")
      expect(result.success?).to be(true)
    end
  end

  describe ".cast" do
    it "returns self if already a DataObject" do
      instance = subclass.new(valid_input)
      expect(subclass.cast(instance)).to equal(instance)
    end

    it "raises for unsupported types" do
      expect { subclass.cast("nope") }.to raise_error(Castkit::DataObjectError)
    end
  end

  describe ".build" do
    it "builds a subclass even without a block" do
      built = described_class.build
      expect(built).to be < described_class
    end
  end

  describe ".serializer" do
    it "allows overriding serializer" do
      custom = Class.new(Castkit::Serializers::Base) do
        def call
          { custom: object.__raw }
        end
      end

      subclass.serializer(custom)
      instance = subclass.new(valid_input)

      expect(instance.to_hash).to eq(custom: instance.__raw)
    end
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

  describe ".build" do
    it "builds a subclass even without a block" do
      built = described_class.build
      expect(built.superclass).to eq(described_class)
    end
  end

  describe ".serializer" do
    it "gets and sets a custom serializer" do
      custom_serializer = Class.new(Castkit::Serializers::Base)
      subclass.serializer(custom_serializer)
      expect(subclass.serializer).to eq(custom_serializer)
    end

    it "raises if serializer is not a Castkit::Serializers::Base" do
      expect do
        subclass.serializer(Class.new)
      end.to raise_error(ArgumentError, /must inherit from Castkit::Serializers::Base/)
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
      end.to raise_error(Castkit::ContractError, /Unknown attribute/)
    end

    it "raises on unknown keys in strict mode when allow_unknown is also false" do
      subclass.strict true
      subclass.allow_unknown false

      expect do
        subclass.new(valid_input.merge(extra: 1))
      end.to raise_error(Castkit::ContractError, /Unknown attribute/)
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

    it "accepts attributes defined on a parent class" do
      sorted_query = Class.new(described_class) do
        optional do
          string :sort
        end
      end

      filtered_sorted = Class.new(sorted_query) do
        optional do
          string :filter
        end
      end

      expect do
        filtered_sorted.new(sort: "auto")
      end.not_to raise_error
    end

    it "accepts camelCase string keys from JSON input" do
      dto = Class.new(described_class) do
        string :logoColor
      end

      input = { "logoColor" => "blue" }

      expect { dto.new(input) }.not_to raise_error
      expect(dto.new(input).logoColor).to eq("blue")
    end
  end

  describe "#strict?" do
    it "returns false when allow_unknown is true" do
      klass = Class.new(described_class) do
        allow_unknown true
      end

      expect(klass.new({}).send(:strict?)).to be(false)
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

  describe "introspection (Cattri opt-in)" do
    let(:introspective_klass) do
      Class.new(described_class) do
        enable_cattri_introspection!
        string :name
        string :email, required: false
      end
    end

    it "exposes introspection helpers when enabled" do
      expect(introspective_klass).to respond_to(:attribute_defined?)
      expect(introspective_klass.attribute_defined?(:name)).to be(true)
      expect(introspective_klass.attribute_methods[:name]).to include(:name, :name=)
      expect(introspective_klass.attribute_source(:name)).to eq(introspective_klass)
      expect(introspective_klass.attribute_definitions[:name]).to be_a(Cattri::Attribute)
    end

    it "memoizes the cattri attribute registry" do
      registry = double("Registry",
                        defined_attributes: { name: double(allowed_methods: %i[name name=],
                                                           defined_in: introspective_klass) })

      allow(introspective_klass).to receive(:attribute_registry).and_return(registry)
      introspective_klass.attribute_methods

      expect(introspective_klass).not_to receive(:attribute_registry)
      introspective_klass.attribute_methods
    end
  end

  describe "deserialization failures" do
    it "raises when value cannot be cast to any union type" do
      failing_type = Class.new(Castkit::Types::Base) do
        def deserialize(_value)
          raise Castkit::TypeError, "nope"
        end
      end

      begin
        Castkit.configuration.register_type(:failing_union, failing_type, override: true)
        attribute = Castkit::Attribute.new(:status, [:failing_union])
        instance = subclass.allocate

        expect do
          instance.send(:deserialize_primitive_value!, attribute, "nope")
        end.to raise_error(Castkit::AttributeError, /could not be deserialized/)
      ensure
        Castkit.configuration.reset_types!
      end
    end

    it "treats allow_unknown as overriding strict? on the instance" do
      relaxed = Class.new(described_class) do
        allow_unknown true
      end

      expect(relaxed.new(valid_input).send(:strict?)).to be(false)
    end

    it "respects explicit strict flag when allow_unknown is false" do
      strict_class = Class.new(described_class) do
        strict true
        string :name
        integer :age
      end

      relaxed_class = Class.new(described_class) do
        strict false
        string :name
        integer :age
      end

      expect(strict_class.new(name: "x", age: 1).send(:strict?)).to be(true)
      expect(relaxed_class.new(name: "x", age: 1).send(:strict?)).to be(false)
    end
  end
end
