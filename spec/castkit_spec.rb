# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"

RSpec.describe Castkit do
  it "has a version number" do
    expect(Castkit::VERSION).not_to be nil
  end

  describe Castkit::DataObject do
    describe "with optional attributes" do
      let(:klass) do
        Class.new(described_class) do
          attribute :name, :string, required: false
          attribute :age, :integer, required: false
          attribute :meta, :hash, aliases: [:metadata], required: false
        end
      end

      it "allows missing optional attributes" do
        instance = klass.new(name: "Tester")
        expect(instance.name).to eq("Tester")
        expect(instance.age).to be_nil
        expect(instance.meta).to be_nil
      end

      it "resolves aliased keys" do
        instance = klass.new(metadata: { foo: "bar" })
        expect(instance.meta).to eq({ foo: "bar" })
      end

      it "serializes to hash" do
        instance = klass.new(name: "Tester", age: 42)
        expect(instance.to_h).to eq(name: "Tester", age: 42, meta: nil)
      end

      it "serializes to JSON" do
        instance = klass.new(name: "Tester", age: 42)
        json = JSON.parse(instance.to_json)
        expect(json).to eq("name" => "Tester", "age" => 42, "meta" => nil)
      end
    end

    describe "with required attributes (default)" do
      let(:klass) do
        Class.new(described_class) do
          attribute :name, :string
          attribute :age, :integer
        end
      end

      it "raises if a required attribute is missing" do
        expect do
          klass.new(age: 21)
        rescue Castkit::ContractError => e
          expect(e.errors).to include(name: "name is required")
          raise e
        end.to raise_error(Castkit::ContractError)
      end

      it "raises if all required attributes are missing" do
        expect do
          klass.new({})
        rescue Castkit::ContractError => e
          expect(e.errors).to include(
            name: "name is required",
            age: "age is required"
          )

          raise e
        end.to raise_error(Castkit::ContractError)
      end

      it "initializes when all required attributes are present" do
        instance = klass.new(name: "Tester", age: 42)
        expect(instance.name).to eq("Tester")
        expect(instance.age).to eq(42)
      end
    end

    describe ".cast" do
      let(:klass) do
        Class.new(described_class) do
          attribute :name, :string, required: false
        end
      end

      it "returns self if already a DataObject" do
        instance = klass.new(name: "foo")
        expect(klass.cast(instance)).to equal(instance)
      end

      it "instantiates from a hash" do
        result = klass.cast({ name: "bar" })
        expect(result).to be_a(klass)
        expect(result.name).to eq("bar")
      end

      it "raises for invalid input types" do
        expect do
          klass.cast(:bad)
        end.to raise_error(Castkit::DataObjectError, /can't cast/i)
      end
    end

    describe ".dump" do
      let(:klass) do
        Class.new(described_class) do
          attribute :name, :string, required: false
        end
      end

      it "calls to_json on the object" do
        instance = klass.new(name: "foo")
        expect(klass.dump(instance)).to eq(instance.to_json)
      end
    end
  end

  describe "real-world examples" do
    before do
      stub_const("Profile", Class.new(Castkit::DataObject) do
        attribute :bio, :string, required: false
        attribute :website, :string, required: false
      end)

      stub_const("User", Class.new(Castkit::DataObject) do
        attribute :id, :string
        attribute :email, :string
        attribute :profile, Profile, required: false
        attribute :tags, :array, of: :string, required: false
        attribute :data, :hash, required: false
      end)

      Castkit.configuration.enforce_typing = true
    end

    it "instantiates with flat fields" do
      user = User.new(id: "123", email: "nathan@example.com")
      expect(user.id).to eq("123")
      expect(user.email).to eq("nathan@example.com")
      expect(user.profile).to be_nil
      expect(user.tags).to be_nil
    end

    it "instantiates with nested DTO" do
      user = User.new(id: "123", email: "a@b.com", profile: { bio: "Hi", website: "me.com" })
      expect(user.profile).to be_a(Profile)
      expect(user.profile.bio).to eq("Hi")
    end

    it "serializes nested DTOs" do
      user = User.new(id: "1", email: "x@y", profile: { bio: "dev" })
      expect(user.to_h).to eq(
        id: "1",
        email: "x@y",
        profile: { bio: "dev", website: nil },
        tags: nil,
        data: nil
      )
    end

    it "casts arrays of strings correctly" do
      user = User.new(id: "1", email: "test@t", tags: %w[dev ruby])
      expect(user.tags).to eq(%w[dev ruby])
    end

    it "allows arbitrary hashes via :hash type" do
      user = User.new(id: "1", email: "hash@case.com", data: { foo: "bar", x: [1, 2, 3] })
      expect(user.data).to eq({ foo: "bar", x: [1, 2, 3] })
    end

    it "raises for missing required fields" do
      expect do
        User.new(email: "no_id@example.com")
      rescue Castkit::ContractError => e
        expect(e.errors).to include(id: "id is required")
        raise e
      end.to raise_error(Castkit::ContractError)
    end

    it "raises on incorrect types in array" do
      expect do
        User.new(id: "ok", email: "y", tags: [true])
      rescue Castkit::ContractError => e
        expect(e.errors).to include(tags: { 0 => "tags[0] must be a string" })
        raise e
      end.to raise_error(Castkit::ContractError)
    end

    it "serializes cleanly to JSON" do
      user = User.new(id: "99", email: "x", tags: ["a"], profile: { bio: "yes" })
      json = JSON.parse(user.to_json)

      expect(json).to include(
        "id" => "99",
        "email" => "x",
        "tags" => ["a"],
        "profile" => include("bio" => "yes")
      )
    end
  end
end
