# frozen_string_literal: true

require_relative "class_declaration"

module Castkit
  module Core
    class DslBase
      extend Castkit::Core::ClassDeclaration
    end
  end
end
