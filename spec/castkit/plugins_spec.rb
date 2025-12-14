# frozen_string_literal: true

require "spec_helper"
require "castkit"

RSpec.describe Castkit::Plugins do
  before do
    @original_registry = described_class.registered_plugins.dup if described_class.respond_to?(:registered_plugins)
  end

  after do
    if described_class.respond_to?(:registered_plugins) && @original_registry
      described_class.registered_plugins.replace(@original_registry)
    end
  end

  it "allows registering a plugin via configuration" do
    plugin_module = Module.new

    Castkit.configure do |config|
      config.register_plugin(:path_plugin, plugin_module)
    end

    expect(Castkit::Plugins.lookup!(:path_plugin)).to eq(plugin_module)
    expect(Castkit::Plugins.registered_plugins[:path_plugin]).to eq(plugin_module)
  end

  it "looks up plugins defined under Castkit::Plugins namespace" do
    stub_const("Castkit::Plugins::SamplePlugin", Module.new)

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

  it "activates plugins that do not implement setup!" do
    plugin = Module.new do
      def marker; end
    end

    Castkit::Plugins.register(:no_setup, plugin)
    klass = Class.new

    expect { Castkit::Plugins.activate(klass, :no_setup) }.not_to raise_error
    expect(klass.new).to respond_to(:marker)
  end

  it "records deactivation requests" do
    klass = Class.new
    expect { Castkit::Plugins.deactivate(klass, :foo, :bar) }.not_to raise_error
    expect(Castkit::Plugins.instance_variable_get(:@deactivate_plugins)).to include(:foo, :bar)
  end

  it "allows disable_plugins no-op when no plugins provided" do
    klass = Class.new(Castkit::DataObject)
    expect { klass.disable_plugins }.not_to raise_error
  end

  it "raises a helpful error when plugin is missing" do
    expect do
      Castkit::Plugins.lookup!(:unknown_plugin)
    end.to raise_error(Castkit::Error, /could not be found/)
  end
end
