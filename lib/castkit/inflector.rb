# frozen_string_literal: true

module Castkit
  # Provides string transformation utilities used internally by Castkit
  module Inflector
    class << self
      # Returns the unqualified class name from a namespaced class.
      #
      # @example
      #   Castkit::Inflector.class_name(Foo::Bar) # => "Bar"
      #
      # @param klass [Class]
      # @return [String]
      def unqualified_name(klass)
        klass.name.to_s.split("::").last
      end

      # Converts a snake_case or underscored string into PascalCase.
      #
      # @example
      #   Castkit::Inflector.pascalize("user_contract") # => "UserContract"
      #   Castkit::Inflector.pascalize(:admin_dto)      # => "AdminDto"
      #
      # @param string [String, Symbol] the input to convert
      # @return [String] the PascalCase representation
      def pascalize(string)
        underscore(string).to_s.split("_").map(&:capitalize).join
      end

      # Converts a PascalCase or camelCase string to snake_case.
      #
      # @example
      #   Castkit::Inflector.underscore("UserContract") # => "user_contract"
      #   Castkit::Inflector.underscore("XMLParser")    # => "xml_parser"
      #
      # @param string [String, Symbol]
      # @return [String]
      def underscore(string)
        string
          .to_s
          .gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
      end
    end
  end
end
