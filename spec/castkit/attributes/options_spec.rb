# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Attributes::Options do
  let(:definition_class) do
    Class.new do
      extend Castkit::Attributes::Options

      def self.definition
        @definition ||= {
          type: nil,
          options: Castkit::Attributes::Options::DEFAULTS.dup
        }
      end

      def self.options
        definition[:options]
      end

      def self.to_h
        definition
      end
    end
  end

  before do
    definition_class.instance_variable_set(
      :@definition,
      { type: nil, options: Castkit::Attributes::Options::DEFAULTS.dup }
    )
  end

  it "returns nil when type is unset and assigns when provided" do
    expect(definition_class.type).to be_nil
    expect(definition_class.type(:string)).to eq(:string)
  end

  it "only sets :of when type is :array" do
    definition_class.type(:string)
    expect(definition_class.of(:integer)).to be_nil

    definition_class.type(:array)
    definition_class.instance_variable_set(:@type, :array)
    definition_class.of(:integer)
    expect(definition_class.options[:of]).to eq(:integer)
  end

  it "normalizes and validates types" do
    expect(definition_class.send(:process_type, TrueClass)).to eq(:boolean)
    expect(definition_class.send(:process_type, String)).to eq(:string)
    expect(definition_class.send(:process_type, :symbolic)).to eq(:symbolic)

    expect do
      definition_class.send(:process_type, Object.new)
    end.to raise_error(Castkit::AttributeError)
  end

  it "respects nil in set_option and validates access modes" do
    expect(definition_class.send(:set_option, :custom, nil)).to be_nil

    definition_class.readonly
    expect(definition_class.options[:access]).to eq([:read])

    definition_class.required(false)
    expect(definition_class.options[:required]).to be(true)

    expect do
      definition_class.send(:validate_access_modes!, [:bogus])
    end.to raise_error(Castkit::AttributeError, /Unknown access flags/)
  end

  it "returns booleans from option predicates" do
    definition_class.required true
    definition_class.default "x"
    definition_class.force_type
    definition_class.ignore
    definition_class.ignore_nil true
    definition_class.ignore_blank true
    definition_class.composite true
    definition_class.transient true
    definition_class.unwrapped true
    definition_class.prefix :pre
    definition_class.readonly false
    definition_class.access %i[read write]
    definition_class.validator -> {}
    definition_class.format(/x/)
    definition_class.of :string # ignored because type is nil

    expect(definition_class.options[:default]).to eq("x")
    expect(definition_class.options[:force_type]).to eq(false)
    expect(definition_class.options[:ignore]).to eq(true)
    expect(definition_class.options[:required]).to eq(true)
    expect(definition_class.options[:ignore_nil]).to eq(true)
    expect(definition_class.options[:ignore_blank]).to eq(true)
    expect(definition_class.options[:composite]).to eq(true)
    expect(definition_class.options[:transient]).to eq(true)
    expect(definition_class.options[:unwrapped]).to eq(true)
    expect(definition_class.options[:prefix]).to eq(:pre)
    expect(definition_class.options[:access]).to eq(%i[read write])
    expect(definition_class.options[:validator]).to be_a(Proc)
    expect(definition_class.options[:format]).to eq(/x/)
    expect(definition_class.options[:of]).to be_nil
  end
end
