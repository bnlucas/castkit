# frozen_string_literal: true

require "thor/group"
require "castkit/inflector"
require_relative "base"

module Castkit
  module Generators
    # Generator for creating Castkit plugin modules.
    #
    # This generator will produce a module under `Castkit::Plugins::<ClassName>` and an optional spec file.
    #
    # Example:
    #   $ castkit generate plugin Oj
    #
    # This will generate:
    # - lib/castkit/plugins/oj.rb
    # - spec/castkit/plugins/oj_spec.rb
    #
    # @see Castkit::Generators::Base
    class Plugin < Castkit::Generators::Base
      component :plugin
    end
  end
end
