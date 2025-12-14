# frozen_string_literal: true

require "cattri"

module Castkit
  # Internal registry for Castkit plugin modules.
  #
  # This module supports registering, activating, and looking up Castkit plugins.
  # Plugins are typically included in Castkit::DataObject subclasses via `.enable_plugins`.
  #
  # Plugins can be defined under `Castkit::Plugins::<Name>` or manually registered
  # through the configuration API.
  #
  # @example Registering a custom plugin
  #   Castkit.configure do |config|
  #     config.register_plugin(:custom, MyCustomPlugin)
  #   end
  #
  # @example Enabling plugins on a DataObject
  #   class MyDto < Castkit::DataObject
  #     enable_plugins :custom, :oj
  #   end
  module Plugins
    include Cattri

    class << self
      include Cattri
      extend Cattri::Dsl
      extend Cattri::ClassMethods
      extend Cattri::Visibility

      cattri :registered_plugins, {}, expose: :read_write

      # Activates one or more plugins on the given class.
      #
      # Each plugin module is included into the class. If the module responds to `setup!`,
      # it will be called with the class as the argument.
      #
      # @param klass [Class] the target class (usually a Castkit::DataObject subclass)
      # @param names [Array<Symbol>] plugin names (e.g., :oj, :yaml)
      # @return [void]
      def activate(klass, *names)
        names.each do |name|
          plugin = lookup!(name)
          klass.include(plugin) if plugin
          plugin.setup!(klass) if plugin.respond_to?(:setup!)
        end
      end

      # (Placeholder) Deactivates plugins by name.
      #
      # Currently not implemented, included for future API completeness.
      #
      # @param _klass [Class] the class to deactivate plugins on
      # @param names [Array<Symbol>] plugin names to deactivate
      # @return [void]
      def deactivate(_klass, *names)
        @deactivate_plugins = names
      end

      # Looks up a plugin module by name.
      #
      # This will first check the internal registry, then fall back to
      # resolving a constant under `Castkit::Plugins::<Name>`.
      #
      # @param name [Symbol, String] the plugin name (e.g., :oj)
      # @return [Module] the plugin module
      # @raise [Castkit::Error] if no plugin is found
      def lookup!(name)
        registered_plugins[name.to_sym] ||
          const_get(Castkit::Inflector.pascalize(name.to_s), false)
      rescue NameError
        raise Castkit::Error,
              "Castkit plugin `#{name}` could not be found. Make sure it is " \
              "defined under Castkit::Plugins or registered using " \
              "`Castkit.configure { |c| c.register_plugin(:#{name}, MyPlugin) }`."
      end

      # Registers a plugin module under a custom name.
      #
      # This allows developers to register modules not defined under Castkit::Plugins.
      #
      # @param name [Symbol] the plugin name (e.g., :custom_plugin)
      # @param plugin [Module] the plugin module to register
      # @return [void]
      def register(name, plugin)
        registered_plugins[name.to_sym] = plugin
      end
    end
  end
end
