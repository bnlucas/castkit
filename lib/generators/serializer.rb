# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating a custom Castkit serializer.
    #
    # Serializers inherit from `Castkit::Serializers::Base` and define a custom `#call` method
    # for rendering a `Castkit::DataObject` into a hash representation.
    #
    # Example usage:
    #   $ castkit generate serializer Custom
    #
    # Generates:
    # - lib/castkit/serializers/custom.rb
    # - spec/castkit/serializers/custom_spec.rb
    #
    # These files scaffold a `Castkit::Serializers::Custom` serializer with the correct base class.
    #
    # @see Castkit::Generators::Base
    class Serializer < Castkit::Generators::Base
      component :serializer
    end
  end
end
