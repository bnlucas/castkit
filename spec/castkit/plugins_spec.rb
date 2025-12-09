# frozen_string_literal: true

require "spec_helper"
require "castkit"

RSpec.describe Castkit::Plugins do
  before do
    @original_registry = described_class.instance_variable_get(:@registered_plugins).dup
  end

  after do
    described_class.instance_variable_set(:@registered_plugins, @original_registry)
  end

  it "allows registering a plugin via configuration" do
    plugin_module = Module.new

    Castkit.configure do |config|
      config.register_plugin(:path_plugin, plugin_module)
    end

    expect(Castkit::Plugins.lookup!(:path_plugin)).to eq(plugin_module)
  end

  it "looks up plugins defined under Castkit::Plugins namespace" do
    module Castkit
      module Plugins
        module SamplePlugin; end
      end
    end

    expect(Castkit::Plugins.lookup!(:sample_plugin)).to eq(Castkit::Plugins::SamplePlugin)
  end

  it "activates plugins by including them and invoking setup!" do
    plugin = Module.new do
      def self.setup!(klass)
        klass.instance_variable_set(:@setup_called, true)
      end

      def plugin_method; end
    end

    Castkit::Plugins.register(:custom, plugin)

    klass = Class.new
    Castkit::Plugins.activate(klass, :custom)

    expect(klass.instance_variable_get(:@setup_called)).to be(true)
    expect(klass.new).to respond_to(:plugin_method)
  end
end
