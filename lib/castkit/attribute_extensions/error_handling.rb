# frozen_string_literal: true

require_relative "../castkit"

module Castkit
  module AttributeExtensions
    # Provides centralized handling of attribute casting and validation errors.
    #
    # The behavior of each error is controlled by configuration flags in `Castkit.configuration`.
    module ErrorHandling
      # Maps known error types to their handling behavior.
      #
      # Each entry includes:
      # - `:config` – the config flag that determines enforcement
      # - `:message` – a lambda that generates an error message
      # - `:error` – the error class to raise
      #
      # @return [Hash<Symbol, Hash>]
      ERROR_OPTIONS = {
        array_of_type: {
          config: :enforce_array_of_type,
          message: ->(*_) { "`of:` must be provided for array type" },
          error: Castkit::AttributeError
        },
        primitive: {
          config: :enforce_known_primitive_type,
          message: ->(_attr, type:) { "unknown primitive type: #{type.inspect}" },
          error: Castkit::AttributeError
        },
        boolean: {
          config: :enforce_boolean_casting,
          message: ->(_attr, value:) { "must be a boolean, got: #{value.inspect}" },
          error: Castkit::AttributeError
        },
        union: {
          config: :enforce_union_match,
          message: ->(_attr, types:) { "could not be cast to any of #{types.inspect}" },
          error: Castkit::AttributeError
        },
        access: {
          config: :enforce_attribute_access,
          message: ->(_attr, mode:) { "invalid access mode `#{mode}`" },
          error: Castkit::AttributeError
        },
        unwrapped: {
          config: :enforce_unwrapped_prefix,
          message: ->(*_) { "prefix can only be used with unwrapped attribute" },
          error: Castkit::AttributeError
        },
        array_options: {
          config: :enforce_array_options,
          message: ->(*_) { "array attribute must specify `of:` type" },
          error: Castkit::AttributeError
        }
      }.freeze

      private

      # Handles a validation or casting error based on the provided error key and context.
      #
      # If the corresponding configuration flag is enabled, an exception is raised.
      # Otherwise, a warning is logged and the method returns `nil`.
      #
      # @param key [Symbol] the type of error (must match a key in ERROR_OPTIONS)
      # @param kwargs [Hash] additional values passed to the message lambda
      # @option kwargs [Symbol] :context (optional) the attribute context (e.g., field name)
      # @return [nil]
      # @raise [Castkit::AttributeError] if enforcement is enabled for the given error type
      def handle_error(key, **kwargs)
        config_key = ERROR_OPTIONS.dig(key, :config)
        message_fn = ERROR_OPTIONS.dig(key, :message)
        error_class = ERROR_OPTIONS.dig(key, :error) || Castkit::Error

        context = kwargs.delete(:context)
        message = message_fn.call(self, **kwargs)
        raise error_class.new(message, context: context) if Castkit.configuration.public_send(config_key)

        warn "[Castkit] #{message}"
        nil
      end
    end
  end
end
