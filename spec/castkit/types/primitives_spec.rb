# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Primitive type wrappers" do
  it "deserializes and validates float" do
    expect(Castkit::Types::Float.deserialize("1.2")).to eq(1.2)
    expect(Castkit::Types::Float.serialize(1.2)).to eq(1.2)
    expect { Castkit::Types::Float.validate!(1.2) }.not_to raise_error
    expect { Castkit::Types::Float.validate!("x") }.to raise_error(Castkit::AttributeError)
  end

  it "deserializes and validates integer" do
    expect(Castkit::Types::Integer.deserialize("3")).to eq(3)
    expect(Castkit::Types::Integer.serialize(3)).to eq(3)
    expect { Castkit::Types::Integer.validate!(3) }.not_to raise_error
    expect { Castkit::Types::Integer.validate!("x") }.to raise_error(Castkit::AttributeError)
  end

  it "deserializes and validates boolean" do
    expect(Castkit::Types::Boolean.deserialize("1")).to eq("1")
    expect(Castkit::Types::Boolean.serialize(false)).to eq(false)
    expect { Castkit::Types::Boolean.validate!(true) }.not_to raise_error
    expect { Castkit::Types::Boolean.validate!("x") }.to raise_error(Castkit::AttributeError)
  end

  it "deserializes and validates date and datetime" do
    date = Date.new(2024, 1, 2)
    expect(Castkit::Types::Date.deserialize("2024-01-02")).to eq(date)
    expect(Castkit::Types::Date.serialize(date)).to eq("2024-01-02")
    expect { Castkit::Types::Date.deserialize("x") }.to raise_error(ArgumentError)
    expect { Castkit::Types::Date.validate!(date) }.not_to raise_error

    parsed = Castkit::Types::DateTime.deserialize("2024-01-02T03:04:05Z")
    expect(parsed).to be_a(DateTime)
    expect(parsed.year).to eq(2024)
    expect { Castkit::Types::DateTime.deserialize("x") }.to raise_error(ArgumentError)
    expect { Castkit::Types::DateTime.validate!(DateTime.now) }.not_to raise_error
    expect(Castkit::Types::DateTime.serialize(parsed)).to eq("2024-01-02T03:04:05+00:00")
  end

  it "deserializes and validates collection" do
    expect(Castkit::Types::Collection.deserialize([1, 2])).to eq([1, 2])
    expect do
      Castkit::Types::Collection.validate!([1, 2], options: {}, context: :tags)
    end.not_to raise_error
    expect { Castkit::Types::Collection.validate!("x") }.to raise_error(Castkit::AttributeError)
  end

  it "exposes base class helpers" do
    expect(Castkit::Types::Base.serialize("x")).to eq("x")
  end
end
