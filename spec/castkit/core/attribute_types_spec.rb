# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Core::AttributeTypes do
  it "extends including class with type helpers and initializes config" do
    klass = Class.new do
      include Castkit::Core::AttributeTypes
      extend Castkit::Core::Attributes
    end

    klass.string :name
    instance = klass.new
    instance.name = "hi"

    expect(instance.name).to eq("hi")
  end

  it "supports dynamic DSL definition for registered types" do
    klass = Class.new do
      extend Castkit::Core::Attributes
      include Castkit::Core::AttributeTypes
    end

    Castkit::Core::AttributeTypes.define_type_dsl(:custom_type)
    allow(klass).to receive(:attribute)

    klass.custom_type :field, foo: :bar
    expect(klass).to have_received(:attribute).with(:field, :custom_type, foo: :bar)
  end

  it "falls back to Object#hash when called without arguments" do
    klass = Class.new do
      include Castkit::Core::AttributeTypes

      def attribute(*); end
    end

    expect { klass.hash }.not_to raise_error
  end

  it "raises when dataobject type is not a subclass of Castkit::DataObject" do
    klass = Class.new do
      include Castkit::Core::AttributeTypes
      extend Castkit::Core::Attributes
    end

    expect do
      klass.dataobject(:bad, String)
    end.to raise_error(Castkit::AttributeError, /must extend/)
  end

  it "defines helper methods for all built-in types" do
    recorded = []
    klass = Class.new do
      extend Castkit::Core::Attributes
      include Castkit::Core::AttributeTypes

      define_singleton_method(:attribute) { |field, type, **| recorded << [field, type] }
    end

    klass.integer :a
    klass.boolean :b
    klass.float :c
    klass.date :d
    klass.datetime :e
    klass.array :f, of: :string
    klass.hash :g
    dataobject_type = Class.new(Castkit::DataObject)
    klass.dataobject(:h, dataobject_type)
    klass.unwrapped(:h, dataobject_type)
    klass.hash

    expect(recorded).to include(
      %i[a integer],
      %i[b boolean],
      %i[c float],
      %i[d date],
      %i[e datetime],
      %i[f array],
      %i[g hash]
    )
    h_entries = recorded.select { |field, _| field == :h }
    expect(h_entries.size).to eq(2)
    expect(h_entries).to all(satisfy { |_, type| type == dataobject_type })
  end
end
