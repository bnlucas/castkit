# frozen_string_literal: true

require "spec_helper"
require "castkit/attribute_extensions/access"

RSpec.shared_examples "writeability check" do |access:, composite:, expected:|
  it "returns #{expected} for access: #{access}, composite: #{composite}" do
    instance = dummy_class.new(access: access, composite: composite)
    expect(instance.writeable?).to eq(expected)
  end
end

RSpec.shared_examples "serialization skip check" do |access:, ignore:, expected:|
  it "returns #{expected} for access: #{access}, ignore: #{ignore}" do
    instance = dummy_class.new(access: access, ignore: ignore)
    expect(instance.skip_serialization?).to eq(expected)
  end
end

RSpec.describe Castkit::AttributeExtensions::Access do
  let(:dummy_class) do
    Class.new do
      include Castkit::AttributeExtensions::Access

      attr_reader :options

      def initialize(**options)
        @options = { access: %i[read write], composite: false, ignore: false }.merge(options)
      end

      def composite?
        options[:composite]
      end
    end.freeze
  end

  let(:options) { {} }

  subject(:instance) { dummy_class.new(**options) }

  describe ".access" do
    it "returns [:read, :write] when access is not provided" do
      instance = dummy_class.new
      expect(instance.access).to eq(%i[read write])
    end

    context "when access is :read" do
      let(:options) { { access: :read } }

      it "returns [:read]" do
        expect(instance.access).to eq([:read])
      end
    end

    context "when access is :write" do
      let(:options) { { access: :write } }

      it "returns [:write]" do
        expect(instance.access).to eq(%i[write])
      end
    end

    context "when access is [:read, :write]" do
      let(:options) { { access: %i[read write] } }

      it "returns [:write]" do
        expect(instance.access).to eq(%i[read write])
      end
    end
  end

  describe ".readable?" do
    context "when access is :read" do
      let(:options) { { access: :read } }

      it "returns true" do
        expect(instance).to be_readable
      end
    end

    context "when access is :write" do
      let(:options) { { access: :write } }

      it "returns false" do
        expect(instance).not_to be_readable
      end
    end

    context "when access is [:read, :write]" do
      let(:options) { { access: %i[read write] } }

      it "returns true" do
        expect(instance).to be_readable
      end
    end
  end

  describe ".writeable?" do
    include_examples "writeability check", access: :write, composite: true, expected: false
    include_examples "writeability check", access: :write, composite: false, expected: true
    include_examples "writeability check", access: %i[read write], composite: true, expected: false
    include_examples "writeability check", access: %i[read write], composite: false, expected: true

    it "returns false when access is :read" do
      instance = dummy_class.new(access: :read)
      expect(instance.writeable?).to eq(false)
    end
  end

  describe ".full_access?" do
    context "when access is :read" do
      let(:options) { { access: :read } }
      it "returns false" do
        expect(instance).not_to be_full_access
      end
    end

    context "when access is :write" do
      let(:options) { { access: :write } }
      it "returns false" do
        expect(instance).not_to be_full_access
      end
    end

    context "when access is [:read, :write]" do
      let(:options) { { access: %i[read write] } }
      it "returns true" do
        expect(instance).to be_full_access
      end
    end
  end

  describe ".skip_serialization?" do
    include_examples "serialization skip check", access: :read, ignore: true, expected: true
    include_examples "serialization skip check", access: :read, ignore: false, expected: false

    it "returns true when access is :write" do
      instance = dummy_class.new(access: :write)
      expect(instance.skip_serialization?).to eq(true)
    end
  end

  describe ".skip_deserialization?" do
    context "when access is :read" do
      let(:options) { { access: :read } }

      it "returns true" do
        expect(instance.skip_deserialization?).to eq(true)
      end
    end

    context "when access is :write" do
      let(:options) { { access: :write } }

      it "returns false" do
        expect(instance.skip_deserialization?).to eq(false)
      end
    end

    context "when access is [:read, :write]" do
      let(:options) { { access: %i[read write] } }

      it "returns false" do
        expect(instance.skip_deserialization?).to eq(false)
      end
    end
  end

  describe ".ignore?" do
    context "when ignore is true" do
      let(:options) { { ignore: true } }

      it "returns true" do
        expect(instance.ignore?).to eq(true)
      end
    end

    context "when ignore is false" do
      let(:options) { { ignore: false } }

      it "returns false" do
        expect(instance.ignore?).to eq(false)
      end
    end
  end
end
