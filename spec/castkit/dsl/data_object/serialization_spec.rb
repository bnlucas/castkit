# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::DSL::DataObject::Serialization::ClassMethods do
  subject(:host_class) do
    Class.new do
      extend Castkit::DSL::DataObject::Serialization::ClassMethods
    end
  end

  describe ".ignore_blank" do
    it "defaults to true when unset" do
      host_class.remove_instance_variable(:@ignore_blank) if host_class.instance_variable_defined?(:@ignore_blank)

      expect(host_class.instance_variable_defined?(:@ignore_blank)).to be(false)
      expect(host_class.ignore_blank).to be(true)
      expect(host_class.instance_variable_get(:@ignore_blank)).to be(true)
    end

    it "allows toggling the flag to false" do
      host_class.remove_instance_variable(:@ignore_blank) if host_class.instance_variable_defined?(:@ignore_blank)
      host_class.ignore_blank(false)

      expect(host_class.ignore_blank).to be(false)
      expect(host_class.instance_variable_get(:@ignore_blank)).to be(false)
    end
  end
end
