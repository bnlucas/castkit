# frozen_string_literal: true

require "spec_helper"

RSpec.describe Castkit::DSL::DataObject::Plugins do
  let(:base_class) { Class.new(Castkit::DataObject) }

  before do
    @original_defaults = Castkit.configuration.default_plugins.dup
  end

  after do
    Castkit.configuration.default_plugins = @original_defaults
  end

  it "no-ops enable_plugins when no plugins provided" do
    expect { base_class.enable_plugins }.not_to raise_error
  end

  it "no-ops disable_plugins when no plugins provided" do
    expect { base_class.disable_plugins }.not_to raise_error
  end

  it "applies default plugins on inheritance unless disabled" do
    plugin_module = Module.new do
      def self.setup!(klass)
        klass.instance_variable_set(:@plugin_setup_called, true)
      end
    end

    Castkit::Plugins.register(:sample_default, plugin_module)
    Castkit.configuration.default_plugins = [:sample_default]

    base_class.disable_plugins :sample_default

    enabled_subclass = Class.new(base_class) do
      enable_plugins :sample_default
    end
    disabled_subclass = Class.new(base_class) do
      disable_plugins :sample_default
    end
    inherited_disabled = Class.new(disabled_subclass)

    expect(enabled_subclass.instance_variable_get(:@plugin_setup_called)).to be(true)
    expect(disabled_subclass.instance_variable_get(:@plugin_setup_called)).to be_nil
    expect(inherited_disabled.instance_variable_get(:@plugin_setup_called)).to be_nil
  end
end
