# frozen_string_literal: true

require "spec_helper"
require "castkit/data_object"
require "castkit/data_object_extensions/attribute_types"

RSpec.describe Castkit::DataObjectExtensions::AttributeTypes do
  let(:klass) do
    Class.new do
      extend Castkit::DataObjectExtensions::AttributeTypes

      def self.attribute(field, type, **options)
        @attributes ||= []
        @attributes << { field: field, type: type, options: options }
      end

      class << self
        attr_reader :attributes
      end
    end
  end

  describe "type methods" do
    it "registers a string attribute" do
      klass.string :name, required: false
      expect(klass.attributes.last).to eq({ field: :name, type: :string, options: { required: false } })
    end

    it "registers an integer attribute" do
      klass.integer :age, min: 0
      expect(klass.attributes.last).to eq({ field: :age, type: :integer, options: { min: 0 } })
    end

    it "registers a boolean attribute" do
      klass.boolean :admin
      expect(klass.attributes.last).to eq({ field: :admin, type: :boolean, options: {} })
    end

    it "registers a float attribute" do
      klass.float :price
      expect(klass.attributes.last).to eq({ field: :price, type: :float, options: {} })
    end

    it "registers a date attribute" do
      klass.date :dob
      expect(klass.attributes.last).to eq({ field: :dob, type: :date, options: {} })
    end

    it "registers a datetime attribute" do
      klass.datetime :created_at
      expect(klass.attributes.last).to eq({ field: :created_at, type: :datetime, options: {} })
    end

    it "registers an array attribute" do
      klass.array :tags
      expect(klass.attributes.last).to eq({ field: :tags, type: :array, options: {} })
    end

    it "registers a hash attribute" do
      klass.hash :metadata
      expect(klass.attributes.last).to eq({ field: :metadata, type: :hash, options: {} })
    end

    it "registers a dataobject attribute" do
      dto_class = Class.new(Castkit::DataObject)
      klass.dataobject :profile, dto_class, required: false
      expect(klass.attributes.last).to eq({ field: :profile, type: dto_class, options: { required: false } })
    end

    it "raises if dataobject type is not a subclass of Castkit::DataObject" do
      expect do
        klass.dataobject :bad, String
      end.to raise_error(Castkit::AttributeError, /must extend from Castkit::DataObject/)
    end

    it "registers an unwrapped dataobject" do
      dto_class = Class.new(Castkit::DataObject)
      klass.unwrapped :location, dto_class
      expect(klass.attributes.last).to eq({ field: :location, type: dto_class, options: { unwrapped: true } })
    end

    it "aliases collection to array" do
      klass.collection :things
      expect(klass.attributes.last).to eq({ field: :things, type: :array, options: {} })
    end

    it "aliases object to dataobject" do
      dto_class = Class.new(Castkit::DataObject)
      klass.object :thing, dto_class
      expect(klass.attributes.last).to eq({ field: :thing, type: dto_class, options: {} })
    end

    it "aliases dto to dataobject" do
      dto_class = Class.new(Castkit::DataObject)
      klass.dto :thing, dto_class
      expect(klass.attributes.last).to eq({ field: :thing, type: dto_class, options: {} })
    end
  end
end
