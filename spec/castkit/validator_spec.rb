# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Validator do
  it "delegates .call to an instance" do
    klass = Class.new(described_class) do
      def call(value, options:, context:)
        [value, options, context]
      end
    end

    result = klass.call("v", options: { min: 1 }, context: :field)
    expect(result).to eq(["v", { min: 1 }, :field])
  end

  it "raises NotImplementedError by default for #call" do
    expect do
      described_class.new.call("v", options: {}, context: :field)
    end.to raise_error(NotImplementedError)
  end
end
