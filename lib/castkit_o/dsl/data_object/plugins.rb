# frozen_string_literal: true

module Castkit
  module DSL
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
        # Enables one or more plugins on the calling class.
        #
        # @param plugins [Array<Symbol>] plugin identifiers (e.g., :oj, :yaml)
        # @return [void]
        def enable_plugins(*plugins)
          return if plugins.empty?

          enabled_plugins.merge(plugins)
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

          disabled_plugins.merge(plugins)
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

          plugins = Castkit.configuration.default_plugins - disabled_plugins.to_a
          subclass.enable_plugins(*plugins)
        end
      end
    end
  end
end
