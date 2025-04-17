# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"

module Castkit
  module Generators
    # Abstract base class for all Castkit generators.
    #
    # Provides standard behavior for generating a component and optional spec file from
    # ERB templates. Subclasses must define a `component` (e.g., `:type`, `:contract`)
    # and may override `config` or `default_values`.
    #
    # Template variables are injected using the `config` hash, which includes:
    # - `:name`        – underscored version of the component name
    # - `:class_name`  – PascalCase version of the component name
    #
    # @abstract
    class Base < Thor::Group
      include Thor::Actions

      class << self
        # Sets or retrieves the component type (e.g., :type, :data_object).
        #
        # @param value [Symbol, nil]
        # @return [Symbol]
        def component(value = nil)
          value.nil? ? @component : (@component = value)
        end

        # @return [String] the root path to look for templates
        def source_root
          File.expand_path("templates", __dir__)
        end
      end

      argument :name, desc: "The name of the component to generate"
      class_option :spec, type: :boolean, default: true, desc: "Also generate a spec file"

      # Creates the main component file using a template.
      #
      # Template: `component.rb.tt`
      # Target: `lib/castkit/#{component}s/#{name}.rb`
      #
      # @return [void]
      def create_component
        template(
          "#{self.class.component}.rb.tt",
          "lib/castkit/#{self.class.component}s/#{config[:name]}.rb", **config
        )
      end

      # Creates the associated spec file, if enabled.
      #
      # Template: `component_spec.rb.tt`
      # Target: `spec/castkit/#{component}s/#{name}_spec.rb`
      #
      # @return [void]
      def create_spec
        return unless options[:spec]

        template(
          "#{self.class.component}_spec.rb.tt",
          "spec/castkit/#{self.class.component}s/#{config[:name]}_spec.rb", **config
        )
      end

      private

      # Default values for test inputs based on type.
      #
      # These are used in spec templates to provide sample data.
      #
      # @return [Hash{Symbol => Object}]
      def default_values
        {
          string: '"example"',
          integer: 42,
          float: 3.14,
          boolean: true,
          array: [],
          hash: {}
        }
      end

      # Returns the default config hash passed into templates.
      #
      # @return [Hash{Symbol => Object}]
      def config
        {
          name: Castkit::Inflector.underscore(name),
          class_name: Castkit::Inflector.pascalize(name)
        }
      end
    end
  end
end
