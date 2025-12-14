# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Additional validator coverage" do
  let(:config) { Castkit.configuration }

  before do
    @orig_raise = config.raise_type_errors
    @orig_warn = config.enable_warnings
  end

  after do
    config.raise_type_errors = @orig_raise
    config.enable_warnings = @orig_warn
  end

  it "raises on non-array values for collection validator" do
    config.raise_type_errors = true
    validator = Castkit::Validators::CollectionValidator.new
    expect do
      validator.call("not array", options: {}, context: :tags)
    end.to raise_error(Castkit::AttributeError)
  end

  it "raises on non-float values for float validator" do
    config.raise_type_errors = true
    validator = Castkit::Validators::FloatValidator.new
    expect do
      validator.call(1, options: {}, context: :price)
    end.to raise_error(Castkit::AttributeError)
  end

  it "raises on non-integer values for integer validator" do
    config.raise_type_errors = true
    validator = Castkit::Validators::IntegerValidator.new
    expect do
      validator.call("not int", options: {}, context: :age)
    end.to raise_error(Castkit::AttributeError)
  end

  it "passes validation for correct numeric types" do
    collection = Castkit::Validators::CollectionValidator.new
    float_validator = Castkit::Validators::FloatValidator.new
    integer_validator = Castkit::Validators::IntegerValidator.new

    expect { collection.call([1], options: {}, context: :tags) }.not_to raise_error
    expect { float_validator.call(1.5, options: {}, context: :price) }.not_to raise_error
    expect { integer_validator.call(2, options: {}, context: :count) }.not_to raise_error
  end

  it "warns instead of raising when raise_type_errors is false" do
    config.raise_type_errors = false
    config.enable_warnings = true
    validator = Castkit::Validators::Base.new
    expect do
      validator.send(:type_error!, :integer, "nope", context: :id)
    end.to output(/id must be a integer/).to_stderr
  end

  it "silently skips when errors and warnings are disabled" do
    config.raise_type_errors = false
    config.enable_warnings = false
    validator = Castkit::Validators::Base.new

    expect do
      validator.send(:type_error!, :integer, "nope", context: :id)
    end.not_to raise_error
  end

  it "raises NotImplementedError from Validators::Base#call by default" do
    validator = Castkit::Validators::Base.new
    expect { validator.call("x", options: {}, context: :id) }.to raise_error(NotImplementedError)
  end
end
