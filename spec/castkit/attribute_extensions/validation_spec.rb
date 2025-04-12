# frozen_string_literal: true

require "spec_helper"
require "castkit/attribute_extensions/error_handling"
require "castkit/attribute_extensions/options"
require "castkit/attribute_extensions/access"
require "castkit/attribute_extensions/validation"

RSpec.describe Castkit::AttributeExtensions::Validation do
  let(:dummy_class) do
    Class.new do
      include Castkit::AttributeExtensions::Options
      include Castkit::AttributeExtensions::Access
      include Castkit::AttributeExtensions::Validation

      attr_reader :field, :type, :options

      def initialize(type: :string, field: :test_field, **options)
        @type = type
        @field = field
        @options = Castkit::AttributeExtensions::Options::DEFAULT_OPTIONS.merge(options)
      end

      def to_h
        {
          field: field,
          type: type,
          options: options
        }
      end

      def raise_error!(message, context: nil)
        raise Castkit::AttributeError.new(message, context: context || to_h)
      end
    end
  end

  subject(:instance) { dummy_class.new(**options) }
  let(:options) { {} }

  before do
    allow(instance).to receive(:warn)
  end

  describe "#validate!" do
    context "when validator is not callable" do
      let(:options) { { validator: true } }

      it "raises an error" do
        expect do
          instance.send(:validate!)
        end.to raise_error(Castkit::AttributeError, /must respond to `.call`/)
      end
    end

    context "when access is invalid" do
      let(:options) { { access: :invalid } }

      context "when enforcement is enabled" do
        before { Castkit.configuration.enforce_attribute_access = true }

        it "raises an error" do
          expect do
            instance.send(:validate!)
          end.to raise_error(Castkit::AttributeError, /invalid access mode/)
        end
      end

      context "when enforcement is disabled" do
        before { Castkit.configuration.enforce_attribute_access = false }

        it "warns instead of raising" do
          expect(instance).to receive(:warn).with(/invalid access mode/)
          expect { instance.send(:validate!) }.not_to raise_error
        end
      end
    end

    context "when access is valid and unwrapped is valid" do
      let(:options) { { access: :read } }

      it "does not raise an error" do
        expect { instance.send(:validate!) }.not_to raise_error
      end
    end

    context "when prefix is present without unwrapped" do
      let(:options) { { prefix: "foo", unwrapped: false } }

      context "when enforcement is enabled" do
        before { Castkit.configuration.enforce_unwrapped_prefix = true }

        it "raises an error" do
          expect do
            instance.send(:validate!)
          end.to raise_error(Castkit::AttributeError, /prefix can only be used/)
        end
      end

      context "when enforcement is disabled" do
        before { Castkit.configuration.enforce_unwrapped_prefix = false }

        it "warns instead of raising" do
          expect(instance).to receive(:warn).with(/prefix can only be used/)
          expect { instance.send(:validate!) }.not_to raise_error
        end
      end
    end

    context "when type is :array without :of" do
      let(:options) { { type: :array } }

      context "when enforcement is on" do
        before { Castkit.configuration.enforce_array_options = true }

        it "raises" do
          expect do
            instance.send(:validate!)
          end.to raise_error(Castkit::AttributeError, /must specify `of:`/)
        end
      end

      context "when enforcement is off" do
        before { Castkit.configuration.enforce_array_options = false }

        it "warns instead of raising" do
          expect(instance).to receive(:warn).with(/must specify `of:`/)
          expect { instance.send(:validate!) }.not_to raise_error
        end
      end
    end
  end
end
