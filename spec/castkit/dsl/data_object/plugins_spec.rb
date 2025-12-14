# frozen_string_literal: true

require "spec_helper"
require "set"
require "castkit/dsl/data_object/plugins"

module Castkit
  module Plugins
    module Json
      def self.setup!(host)
        host.instance_variable_set(:@plugin_setup_called, true)
      end
    end

    module Wire
      def self.setup!(host)
        host.instance_variable_set(:@plugin_setup_called, true)
      end
    end
  end
end

RSpec.describe Castkit::DSL::DataObject::Plugins do
  before do
    allow(Castkit.configuration).to receive(:default_plugins).and_return([])
  end

  let(:host_class) do
    Class.new(Castkit::DataObject).tap do |klass|
      klass.extend(described_class)
    end
  end

  describe ".enabled_plugins" do
    it "initializes the plugin set when accessed" do
      host_class.remove_instance_variable(:@enabled_plugins) if host_class.instance_variable_defined?(:@enabled_plugins)
      expect(host_class.enabled_plugins).to be_a(Set)
      expect(host_class.instance_variable_defined?(:@enabled_plugins)).to be(true)
    end
  end

  describe ".disabled_plugins" do
    it "initializes the disabled set when accessed" do
      if host_class.instance_variable_defined?(:@disabled_plugins)
        host_class.remove_instance_variable(:@disabled_plugins)
      end
      expect(host_class.disabled_plugins).to be_a(Set)
      expect(host_class.instance_variable_defined?(:@disabled_plugins)).to be(true)
    end
  end

  describe ".enable_plugins" do
    it "adds plugins to the enabled set" do
      host_class.enable_plugins(:json, :wire)
      expect(host_class.enabled_plugins).to include(:json, :wire)
    ensure
      host_class.instance_variable_set(:@enabled_plugins, nil)
    end

    it "is a no-op when no plugins are provided" do
      expect { host_class.enable_plugins }.not_to raise_error
    end
  end

  describe ".disable_plugins" do
    it "adds plugins to the disabled set" do
      host_class.disable_plugins(:xml)
      expect(host_class.disabled_plugins).to include(:xml)
    ensure
      host_class.instance_variable_set(:@disabled_plugins, nil)
    end

    it "no-ops when called without args" do
      host_class.disable_plugins
      expect(host_class.disabled_plugins).not_to be_nil
    end
  end
end
