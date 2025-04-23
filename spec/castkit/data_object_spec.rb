# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"

class TestDto < Castkit::DataObject
  string :name
  integer :age, required: false
end

class RelaxedTestDto < TestDto
  allow_unknown true
end

class WrappedTestDto < TestDto
  root :data

  string :name
  integer :age, required: false
end

RSpec.describe Castkit::DataObject do
  let(:data_object) { TestDto }
  let(:relaxed_data_object) { RelaxedTestDto }
  let(:wrapped_data_object) { WrappedTestDto }

  describe ".build" do
    it "creates a subclass with evaluated block" do
      # stub
    end
  end

  describe ".serializer" do
    it "gets and sets a custom serializer" do
      # stub
    end

    it "raises if serializer is not a Castkit::Serializers::Base" do
      # stub
    end
  end

  describe ".cast" do
    it "returns the same instance if already cast" do
      # stub
    end

    it "casts from hash input" do
      # stub
    end

    it "raises on invalid input types" do
      # stub
    end
  end

  describe ".dump" do
    it "serializes the object to JSON string" do
      # stub
    end
  end

  describe "#initialize" do
    it "initializes from a valid hash" do
      instance = data_object.new(name: "Castkit", age: 23)

      expect(instance.name).to eq "Castkit"
      expect(instance.age).to eq 23
    end

    it "tracks unknown attributes" do
      instance = relaxed_data_object.new(name: "Castkit", age: 23, unknown: "value")

      expect(instance.unknown_attributes).to include(unknown: "value")
    end

    it "raises if unknown attributes are not allowed" do
      # stub
    end

    it "unwraps root key if configured" do
      instance = wrapped_data_object.new(data: { name: "Castkit", age: 23 })

      expect(instance.name).to eq "Castkit"
      expect(instance.age).to eq 23
    end
  end

  describe "#to_hash / #serialize / #to_h" do
    it "serializes using default serializer" do
      # stub
    end

    it "includes unknown attributes when allowed" do
      # stub
    end
  end

  describe "#to_json" do
    it "returns the JSON string" do
      # stub
    end
  end

  describe "#__raw" do
    it "exposes original input data" do
      # stub
    end
  end

  describe "#unknown_attributes" do
    it "returns only unexpected keys" do
      # stub
    end
  end
end
