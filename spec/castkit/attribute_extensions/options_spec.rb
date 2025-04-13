# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"
require "castkit/attribute_extensions/options"

RSpec.describe Castkit::AttributeExtensions::Options do
  let(:dummy_dataobject_class) { Class.new(Castkit::DataObject) }
  let(:dummy_class) do
    Class.new do
      include Castkit::AttributeExtensions::Options

      attr_reader :field, :type, :options

      def initialize(field: :name, type: String, default: nil, **options)
        @field = field
        @type = type
        @default = default
        @options = Castkit::AttributeExtensions::Options::DEFAULT_OPTIONS.merge(options)
      end
    end
  end

  subject(:instance) { dummy_class.new(**options) }
  let(:options) { {} }

  describe "#default" do
    context "when default is a static value" do
      let(:options) { { default: "static" } }

      it "returns the static value" do
        expect(instance.default).to eq("static")
      end
    end

    context "when default is a lambda" do
      let(:options) { { default: -> { "lazy" } } }

      it "returns the evaluated value" do
        expect(instance.default).to eq("lazy")
      end
    end
  end

  describe "#key" do
    context "when options[:key] is not set" do
      it "returns the field" do
        expect(instance.key).to eq(:name)
      end
    end

    context "when options[:key] is set" do
      let(:options) { { key: :custom_key } }

      it "returns the custom key" do
        expect(instance.key).to eq(:custom_key)
      end
    end
  end

  describe "#key_path" do
    context "without aliases" do
      it "returns the split path of the key" do
        expect(instance.key_path).to eq([:name])
      end
    end

    context "with aliases and with_aliases: true" do
      let(:options) { { aliases: ["profile.full_name"] } }

      it "includes alias paths" do
        expect(instance.key_path(with_aliases: true)).to eq([[:name], %i[profile full_name]])
      end
    end

    context "with multiple aliases and with_aliases: true" do
      let(:options) { { aliases: %w[foo.bar baz] } }

      it "combines key path and alias paths" do
        expect(instance.key_path(with_aliases: true)).to eq([[:name], %i[foo bar], [:baz]])
      end
    end
  end

  describe "#alias_paths" do
    let(:options) { { aliases: %w[foo.bar baz] } }

    it "splits aliases into path components" do
      expect(instance.alias_paths).to eq([%i[foo bar], [:baz]])
    end
  end

  describe "#required?" do
    it "returns true by default" do
      expect(instance.required?).to eq(true)
    end

    context "when required is false" do
      let(:options) { { required: false } }

      it "returns false" do
        expect(instance.required?).to eq(false)
      end
    end
  end

  describe "#optional?" do
    it "returns the inverse of required?" do
      expect(instance.optional?).to eq(false)
    end
  end

  describe "#ignore_nil?" do
    it "returns false by default" do
      expect(instance.ignore_nil?).to eq(false)
    end

    context "when ignore_nil is true" do
      let(:options) { { ignore_nil: true } }

      it "returns true" do
        expect(instance.ignore_nil?).to eq(true)
      end
    end
  end

  describe "#composite?" do
    it "returns false by default" do
      expect(instance.composite?).to eq(false)
    end

    context "when composite is true" do
      let(:options) { { composite: true } }

      it "returns true" do
        expect(instance.composite?).to eq(true)
      end
    end
  end

  describe "#dataobject?" do
    context "when type is a DataObject class" do
      let(:options) { { type: dummy_dataobject_class } }

      it "returns true" do
        expect(instance.dataobject?).to eq(true)
      end
    end

    context "when type is a plain Ruby type" do
      let(:options) { { type: String } }

      it "returns false" do
        expect(instance.dataobject?).to eq(false)
      end
    end

    context "when type is a symbol" do
      let(:options) { { type: :foo } }

      it "returns false for dataobject?" do
        expect(instance.dataobject?).to eq(false)
      end
    end
  end

  describe "#unwrapped?" do
    context "when dataobject? is true and unwrapped: true" do
      let(:options) { { type: dummy_dataobject_class, unwrapped: true } }

      it "returns true" do
        expect(instance.unwrapped?).to eq(true)
      end
    end

    context "when unwrapped is true but not a DataObject" do
      let(:options) { { type: String, unwrapped: true } }

      it "returns false" do
        expect(instance.unwrapped?).to eq(false)
      end
    end
  end

  describe "#prefix" do
    context "when prefix is not set" do
      it "returns nil" do
        expect(instance.prefix).to be_nil
      end
    end

    context "when prefix is set" do
      let(:options) { { prefix: "foo" } }

      it "returns the prefix" do
        expect(instance.prefix).to eq("foo")
      end
    end
  end
end
