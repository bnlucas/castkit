# frozen_string_literal: true

require_relative "error_handling"
require_relative "options"

module Castkit
  module Ext
    module Attribute
      # Provides validation logic for attribute configuration.
      #
      # These checks are typically performed at attribute initialization to catch misconfigurations early.
      module Validation
        include Castkit::Ext::Attribute::ErrorHandling

        private

        # Runs all validation checks on the attribute definition.
        #
        # This includes:
        # - Custom validator integrity
        # - Access mode validity
        # - Unwrapped prefix usage
        # - Array `of:` type presence
        #
        # @return [void]
        def validate!
          validate_type!
          validate_custom_validator!
          validate_access!
          validate_unwrapped_options!
          validate_array_options!
        end

        def validate_type!
          types ||= Array(type) # used to test single type and type unions.

          types.each do |t|
            next if Castkit.dataobject?(t) || Castkit.configuration.type_registered?(t)

            raise_error!("Type is not registered, register with Castkit.configuration.register_type(:#{t})")
          end
        end

        # Validates the presence and interface of a custom validator.
        #
        # @return [void]
        # @raise [Castkit::AttributeError] if the validator is not callable
        def validate_custom_validator!
          return unless options[:validator]
          return if options[:validator].respond_to?(:call)

          raise_error!("Custom validator for `#{field}` must respond to `.call`")
        end

        # Validates that each declared access mode is valid.
        #
        # @return [void]
        # @raise [Castkit::AttributeError] if any access mode is invalid and enforcement is enabled
        def validate_access!
          access.each do |mode|
            next if Castkit::Ext::Attribute::Options::DEFAULT_OPTIONS[:access].include?(mode)

            handle_error(:access, mode: mode, context: to_h)
          end
        end

        # Ensures prefix is only used with unwrapped attributes.
        #
        # @return [void]
        # @raise [Castkit::AttributeError] if prefix is used without `unwrapped: true`
        def validate_unwrapped_options!
          handle_error(:unwrapped, context: to_h) if prefix && !unwrapped?
        end

        # Ensures `of:` is provided for array-typed attributes.
        #
        # @return [void]
        # @raise [Castkit::AttributeError] if `of:` is missing for `type: :array`
        def validate_array_options!
          handle_error(:array_options, context: to_h) if type == :array && options[:of].nil?
        end
      end
    end
  end
end
