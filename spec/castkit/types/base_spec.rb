# frozen_string_literal: true

require "spec_helper"
require "castkit/types/base"

RSpec.describe Castkit::Types::Base do
  let(:type_class) do
    Class.new(described_class) do
      def deserialize(value)
        value
      end
    end
  end

  describe ".cast!" do
    it "supports custom validators that accept only the value" do
      validator = ->(v) { raise Castkit::AttributeError, "empty" if v.to_s.empty? }

      expect do
        type_class.cast!("valid", validator: validator)
      end.not_to raise_error

      expect do
        type_class.cast!("", validator: validator)
      end.to raise_error(Castkit::AttributeError, /empty/)
    end

    it "supports custom validators that accept value and options hash" do
      validator = ->(v, opts) { raise Castkit::AttributeError, "missing #{opts[:name]}" if v.nil? }

      expect do
        type_class.cast!("ok", validator: validator, name: "name")
      end.not_to raise_error

      expect do
        type_class.cast!(nil, validator: validator, name: "name")
      end.to raise_error(Castkit::AttributeError, /missing name/)
    end
  end
end
