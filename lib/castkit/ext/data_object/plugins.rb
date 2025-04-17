# frozen_string_literal: true

module Castkit
  module Ext
    module DataObject
      # Provides plugin support for DataObject classes.
      #
      # This module allows a Castkit::DataObject to explicitly declare supported plugins,
      # and ensures all default plugins are enabled on subclassing.
      #
      # Plugins should be defined under `Castkit::Plugins::<Name>` and can be registered
      # globally via `Castkit.configure { |c| c.register_plugin(:name, MyPlugin) }`.
      #
      # Example:
      #   class MyDto < Castkit::DataObject
      #     enable_plugins :oj, :msgpack
      #     disable_plugins :yaml
      #   end
      #
      module Plugins
        # Returns the set of plugins explicitly enabled on the class.
        #
        # @return [Set<Symbol>] enabled plugin names
        def enabled_plugins
          @enabled_plugins ||= Set.new
        end

        # Returns the set of default plugins explicitly disabled on the class.
        #
        # @return [Set<Symbol>] disabled plugin names
        def disabled_plugins
          @disabled_plugins ||= Set.new
        end

        # Enables one or more plugins on the calling class.
        #
        # @param plugins [Array<Symbol>] plugin identifiers (e.g., :oj, :yaml)
        # @return [void]
        def enable_plugins(*plugins)
          return if plugins.empty?

          @enabled_plugins ||= Set.new
          @enabled_plugins.merge(plugins)

          Castkit::Plugins.activate(self, *plugins)
        end

        # Disables one or more default plugins on the calling class.
        #
        # @example
        #   Castkit.configure do |config|
        #     config.default_plugins [:oj, :activerecord]
        #   end
        #
        #   class UserDto < Castkit::DataObject
        #     disable_plugin :activerecord
        #   end
        #
        # @param plugins [Array<Symbol>] plugin identifiers (e.g., :oj, :yaml)
        # @return [void]
        def disable_plugins(*plugins)
          return if plugins.empty?

          @disabled_plugins ||= Set.new
          @disabled_plugins.merge(plugins)
        end

        # Hook that is called when a DataObject subclass is created.
        #
        # Automatically applies `Castkit.configuration.default_plugins`
        # to the subclass.
        #
        # @param subclass [Class] the inheriting subclass
        # @return [void]
        def inherited(subclass)
          super

          disabled = instance_variable_get(:@disabled_plugins) || Set.new
          plugins = Castkit.configuration.default_plugins - disabled.to_a

          subclass.enable_plugins(*plugins)
        end
      end
    end
  end
end
