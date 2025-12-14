# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::Types::Base do
  let(:config) { Castkit.configuration }

  before do
    @orig_raise = config.raise_type_errors
    @orig_warn = config.enable_warnings
  end

  after do
    config.raise_type_errors = @orig_raise
    config.enable_warnings = @orig_warn
  end

  it "casts with force_type before validation" do
    klass = Class.new(described_class) do
      def deserialize(value)
        value.to_i
      end
    end

    result = klass.cast!("5", force_type: true)
    expect(result).to eq(5)
  end

  it "emits a warning instead of raising when configured" do
    config.raise_type_errors = false
    config.enable_warnings = true

    klass = Class.new(described_class) do
      def call_warning
        type_error!(:integer, "bad", context: :field)
      end
    end

    instance = klass.new
    expect { instance.call_warning }.to output(/field must be a integer/).to_stderr
  end

  it "supports validators of varying arity" do
    called = []
    validator1 = lambda { |v|
      called << [:arity1, v]
      v
    }
    validator2 = lambda do |v, opts|
      called << [:arity2, v, opts]
      v + opts[:offset]
    end
    validator3 = lambda do |v, **kw|
      called << [:keyword, v, kw]
      "#{v}-#{kw[:context]}-#{kw.dig(:options, :suffix)}"
    end

    expect(described_class.cast!(1, validator: validator1)).to eq(1)
    result2 = described_class.cast!(1, validator: validator2, options: { offset: 2 })
    expect(result2).to eq(1)
    result3 = described_class.cast!("a", validator: validator3, options: { suffix: "z" }, context: :ctx)
    expect(result3).to eq("a")

    expect(called).to include(
      [:arity1, 1],
      [:arity2, 1, hash_including(offset: 2)],
      [:keyword, "a", hash_including(options: hash_including(suffix: "z"), context: :ctx)]
    )
  end

  it "exposes base serialize/deserialize/validate defaults" do
    base = described_class.new
    expect(base.deserialize("x")).to eq("x")
    expect(base.serialize("y")).to eq("y")
    expect { base.validate!("z") }.not_to raise_error
  end

  it "invokes non-proc validators with keyword options/context" do
    called = []
    validator_obj = Class.new do
      attr_reader :called

      def initialize(called)
        @called = called
      end

      def call(value, options: {}, context: nil)
        called << [value, options, context]
        value
      end
    end.new(called)

    described_class.cast!(5, validator: validator_obj, options: { foo: :bar }, context: :ctx)

    expect(called).to include([5, hash_including(foo: :bar), :ctx])
  end
end
