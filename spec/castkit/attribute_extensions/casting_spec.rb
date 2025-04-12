# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"
require "castkit/attribute_extensions/casting"

def build_stub_dataobject(name: "Stub", &block)
  Class.new(Castkit::DataObject).tap do |klass|
    klass.define_singleton_method(:name) { name }
    klass.define_singleton_method(:cast, &block)
  end
end

RSpec.describe "Castkit::AttributeExtensions::Casting" do
  let(:dummy_dataobject_class) do
    build_stub_dataobject { |input| "safe_cast:#{input}" }
  end

  let(:dummy_class) do
    Class.new do
      include Castkit::AttributeExtensions::Casting
      include Castkit::AttributeExtensions::Options

      attr_reader :type, :options, :field

      def initialize(type:, options: {}, field: :example)
        @type = type
        @options = Castkit::AttributeExtensions::Options::DEFAULT_OPTIONS.merge(options)
        @field = field
      end

      def optional?
        !options[:required]
      end
    end
  end

  subject(:caster) { dummy_class.new(type: type, options: options) }
  let(:options) { {} }

  describe "#cast" do
    context "when value is nil and optional" do
      let(:type) { :string }
      let(:options) { { required: false } }

      it "returns default" do
        expect(caster.send(:cast, nil)).to be_nil
      end
    end

    context "when type is a union" do
      let(:type) { [dummy_dataobject_class, :string] }
      let(:bad_type) { dummy_dataobject_class }

      before do
        allow(bad_type).to receive(:cast).and_raise(Castkit::AttributeError, "fallback failed")
      end

      it "tries each type until one succeeds" do
        expect(caster.send(:cast, "hello")).to be_a(String)
      end

      it "returns a DataObject when matched first" do
        allow(dummy_dataobject_class).to receive(:cast).and_return(:casted)
        expect(caster.send(:cast, "value")).to eq(:casted)
      end

      it "raises if none match" do
        caster = dummy_class.new(type: [bad_type], field: :bad)

        expect do
          caster.send(:cast, "value")
        end.to raise_error(Castkit::AttributeError, /fallback failed/)
      end
    end

    context "when type is a Castkit::DataObject" do
      let(:type) { dummy_dataobject_class }

      it "delegates to the dataobject's cast method" do
        expect(type).to receive(:cast).with("foo")
        caster.send(:cast, "foo")
      end
    end

    context "when type is :array without :of" do
      let(:type) { :array }

      it "raises an error" do
        expect do
          caster.send(:cast, ["value"])
        end.to raise_error(Castkit::AttributeError, /must be provided/)
      end
    end

    context "when type is :array with primitive :of" do
      let(:type) { :array }
      let(:options) { { of: :string } }

      it "casts each element" do
        result = caster.send(:cast, %w[a b c])
        expect(result).to eq(%w[a b c])
      end
    end

    context "when type is :array with DataObject :of" do
      let(:type) { :array }
      let(:options) { { of: dummy_dataobject_class } }

      it "calls cast on each element" do
        allow(dummy_dataobject_class).to receive(:cast).and_return(:obj)
        expect(caster.send(:cast, [{ foo: 1 }, { bar: 2 }])).to eq(%i[obj obj])
      end
    end

    context "when type is :string" do
      let(:type) { :string }

      it "casts to string" do
        expect(caster.send(:cast, 123)).to eq("123")
      end
    end

    context "when type is :integer" do
      let(:type) { :integer }

      it "casts to integer" do
        expect(caster.send(:cast, "42")).to eq(42)
      end
    end

    context "when type is :float" do
      let(:type) { :float }

      it "casts to float" do
        expect(caster.send(:cast, "3.14")).to eq(3.14)
      end
    end

    context "when type is :boolean" do
      let(:type) { :boolean }

      it "casts 'true' to true" do
        expect(caster.send(:cast, "true")).to eq(true)
        expect(caster.send(:cast, "1")).to eq(true)
      end

      it "casts 'false' to false" do
        expect(caster.send(:cast, "false")).to eq(false)
        expect(caster.send(:cast, "0")).to eq(false)
      end

      it "raises for invalid boolean" do
        expect do
          caster.send(:cast, "maybe")
        end.to raise_error(Castkit::AttributeError, /must be a boolean/)
      end
    end

    context "when type is :date" do
      let(:type) { :date }

      it "parses valid date strings" do
        expect(caster.send(:cast, "2022-01-01")).to eq(Date.new(2022, 1, 1))
      end
    end

    context "when type is :datetime" do
      let(:type) { :datetime }

      it "parses valid datetime strings" do
        result = caster.send(:cast, "2022-01-01T12:00:00")
        expect(result).to be_a(DateTime)
        expect(result.to_s).to start_with("2022-01-01T12:00:00")
      end
    end

    context "when type is unknown" do
      let(:type) { :custom }

      it "raises if type is unknown" do
        expect do
          caster.send(:cast, "raw")
        end.to raise_error(Castkit::AttributeError, /unknown primitive type/)
      end
    end
  end
end
