# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Validators::BaseValidator do
  describe ".call" do
    it "instantiates and delegates to instance #call" do
      klass = Class.new(described_class) do
        def call(value, **_options)
          "validated-#{value}"
        end
      end

      expect(klass.call("abc", options: {}, context: :name)).to eq("validated-abc")
    end
  end

  describe "#call" do
    it "raises NotImplementedError by default" do
      expect do
        described_class.new.call("abc", options: {}, context: :field)
      end.to raise_error(NotImplementedError, /must implement `#call`/)
    end
  end
end
