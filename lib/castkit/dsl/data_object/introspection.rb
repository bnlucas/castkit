# frozen_string_literal: true

module Castkit
  module DSL
    module DataObject
      # Provides opt-in attribute introspection for data objects using Cattri's registry
      # without overriding Castkit's attribute DSL.
      module Introspection
        # Enables introspection helpers on the including class.
        #
        # @return [void]
        def enable_cattri_introspection!
          extend IntrospectionHelpers

          @cattri_attribute_registry = nil
        end

        # Class-level helpers that read from Cattri's attribute registry but do not
        # override Castkit's attribute builder.
        module IntrospectionHelpers
          def attribute_defined?(name)
            !!cattri_attribute(name)
          end

          def attribute_definitions(with_ancestors: false)
            cattri_attribute_registry.defined_attributes(with_ancestors: with_ancestors)
          end

          def attribute_methods
            cattri_attribute_registry.defined_attributes(with_ancestors: true).transform_values do |attribute|
              Set.new(attribute.allowed_methods)
            end
          end

          def attribute_source(name)
            cattri_attribute(name)&.defined_in
          end

          private

          def cattri_attribute_registry
            @cattri_attribute_registry ||= attribute_registry
          end

          def cattri_attribute(name)
            cattri_attribute_registry.defined_attributes(with_ancestors: true)[name.to_sym]
          end
        end
      end
    end
  end
end
