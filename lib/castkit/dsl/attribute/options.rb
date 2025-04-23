# frozen_string_literal: true

module Castkit
  module DSL
    module Attributes
      # Provides a DSL for configuring attribute options within an attribute definition.
      #
      # This module is designed to be extended by class-level definition objects such as
      # `Castkit::Attributes::Definition`, and is used to build reusable sets of options
      # for attributes declared within `Castkit::DataObject` classes.
      #
      # @example
      #   class OptionalString < Castkit::Attributes::Definition
      #     type :string
      #     required false
      #     ignore_blank true
      #   end
      module Options
        # Valid access modes for an attribute.
        #
        # @return [Array<Symbol>]
        ACCESS_MODES = %i[read write].freeze

        # Default configuration for attribute options.
        #
        # @return [Hash{Symbol => Object}]
        DEFAULTS = {
          required: true,
          ignore_nil: false,
          ignore_blank: false,
          ignore: false,
          composite: false,
          transient: false,
          unwrapped: false,
          prefix: nil,
          access: ACCESS_MODES,
          force_type: false # TODO: Update to check config
        }.freeze

        # Sets or retrieves the attribute type.
        #
        # @param value [Symbol, nil] The type to assign (e.g., :string), or nil to fetch.
        # @return [Symbol]
        def type(value = nil)
          value.nil? ? definition[:type] : (definition[:type] = value.to_sym)
        end

        # Sets the element type for array attributes.
        #
        # @param value [Symbol, Class] the type of elements in the array
        # @return [void]
        def of(value)
          return unless @type == :array

          set_option(:of, value)
        end

        # Sets the default value or proc for the attribute.
        #
        # @param value [Object, Proc] the default value or lambda
        # @return [void]
        def default(value = nil)
          set_option(:default, value)
        end

        # Enables or disables forced typecasting, or sets a custom flag.
        #
        # @param value [Boolean, nil] the forced type flag
        # @return [void]
        def force_type(value = nil)
          set_option(:force_type, value || !Castkit.configuration.enforce_typing)
        end

        # Marks the attribute as required or optional.
        #
        # @param value [Boolean]
        # @return [void]
        def required(value = nil)
          set_option(:required, value || true)
        end

        # Marks the attribute to be ignored entirely.
        #
        # @param value [Boolean]
        # @return [void]
        def ignore(value = nil)
          set_option(:ignore, value || true)
        end

        # Ignores `nil` values during serialization or persistence.
        #
        # @param value [Boolean]
        # @return [void]
        def ignore_nil(value = nil)
          set_option(:ignore_nil, value || true)
        end

        # Ignores blank values (`""`, `[]`, `{}`) during serialization.
        #
        # @param value [Boolean]
        # @return [void]
        def ignore_blank(value = nil)
          set_option(:ignore_blank, value || true)
        end

        # Adds a prefix for unwrapped attribute keys.
        #
        # @param value [String, Symbol, nil]
        # @return [void]
        def prefix(value = nil)
          set_option(:prefix, value)
        end

        # Marks the attribute as unwrapped (inline merging of nested fields).
        #
        # @param value [Boolean]
        # @return [void]
        def unwrapped(value = nil)
          set_option(:unwrapped, value || true)
        end

        # Sets access modes for the attribute.
        #
        # @param value [Array<Symbol>, Symbol] valid values: `:read`, `:write`, or both
        # @return [void]
        def access(value = nil)
          value = validate_access_modes!(value)
          set_option(:access, value)
        end

        # Shortcut to make the attribute readonly (`access: [:read]`).
        #
        # @param value [Boolean]
        # @return [void]
        def readonly(value = nil)
          value = value || true ? [:read] : ACCESS_MODES
          set_option(:access, value)
        end

        # Marks the attribute as a composite (e.g., nested `DataObject`).
        #
        # @param value [Boolean]
        # @return [void]
        def composite(value = nil)
          set_option(:composite, value || true)
        end

        # Marks the attribute as transient (not included in persistence or serialization).
        #
        # @param value [Boolean]
        # @return [void]
        def transient(value = nil)
          set_option(:transient, value || true)
        end

        # Sets a format constraint (e.g., regex validation).
        #
        # @param value [Regexp]
        # @return [void]
        def format(value)
          set_option(:format, value)
        end

        # Attaches a custom validator callable for this attribute.
        #
        # @param value [Proc, #call]
        # @return [void]
        def validator(value)
          set_option(:validator, value)
        end

        private

        # Converts class or symbol into a normalized type symbol.
        #
        # @param type [Class, Symbol]
        # @return [Symbol]
        # @raise [Castkit::AttributeError] if type cannot be resolved
        def process_type(type)
          case type
          when Class
            return :boolean if [TrueClass, FalseClass].include?(type)

            type.name.downcase.to_sym
          when Symbol
            type
          else
            raise Castkit::AttributeError.new("Unknown type: #{type.inspect}", context: to_h)
          end
        end

        # Sets an option key-value pair in the current definition.
        #
        # @param option [Symbol]
        # @param value [Object, nil]
        # @return [Object, nil]
        def set_option(option, value)
          value.nil? ? definition[:options][option] : (definition[:options][option] = value)
        end

        # Validates and normalizes access mode array.
        #
        # @param value [Array<Symbol>, Symbol, nil]
        # @return [Array<Symbol>]
        # @raise [Castkit::AttributeError] if invalid modes are present
        def validate_access_modes!(value)
          value_array = Array(value || ACCESS_MODES).compact
          unknown_modes = value_array - ACCESS_MODES
          return value_array if unknown_modes.empty?

          raise Castkit::AttributeError.new("Unknown access flags: #{unknown_modes.inspect}", context: to_h)
        end
      end
    end
  end
end
