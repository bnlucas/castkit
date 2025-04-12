# frozen_string_literal: true

require "spec_helper"
require "castkit/serializer"
require "castkit/default_serializer"

RSpec.describe Castkit::Serializer do
  let(:object) { double("SerializableObject") }

  describe ".call" do
    it "instantiates and calls serialize" do
      serializer_class = Class.new(described_class) do
        def call
          { key: "value" }
        end
      end

      expect(serializer_class.call(object)).to eq({ key: "value" })
    end
  end

  describe "#serialize_with_default" do
    it "delegates to Castkit::DefaultSerializer" do
      serializer = Class.new(described_class) do
        public :serialize_with_default
      end.new(object)

      allow(Castkit::DefaultSerializer).to receive(:call).with(object,
                                                               visited: kind_of(Set)).and_return({ fallback: true })

      expect(serializer.serialize_with_default).to eq({ fallback: true })
    end
  end

  describe "#serialize" do
    it "raises on circular references" do
      serializer_class = Class.new(described_class) do
        def call
          # Never gets here
        end
      end

      visited = Set.new([object.object_id])
      instance = serializer_class.new(object, visited: visited)

      expect { instance.send(:serialize) }.to raise_error(Castkit::SerializationError, /Circular reference/)
    end

    it "tracks and untracks object_id in visited set" do
      serializer_class = Class.new(described_class) do
        def call
          { data: true }
        end
      end

      visited = Set.new
      instance = serializer_class.new(object, visited: visited)

      expect(visited).not_to include(object.object_id)
      result = instance.send(:serialize)
      expect(result).to eq({ data: true })
      expect(visited).not_to include(object.object_id) # ensure cleanup
    end
  end

  describe "#call" do
    it "raises NotImplementedError by default" do
      instance = described_class.new(object)
      expect { instance.send(:call) }.to raise_error(NotImplementedError, /must implement `#call`/)
    end
  end
end
