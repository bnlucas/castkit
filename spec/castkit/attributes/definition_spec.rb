# frozen_string_literal: true

require "spec_helper"
require "castkit/attributes/definition"

RSpec.describe Castkit::Attributes::Definition do
  it "returns options via .options" do
    definition = Class.new(described_class)
    expect(definition.options).to be_a(Hash)
    expect(definition.options[:required]).to eq(true)
  end
end
