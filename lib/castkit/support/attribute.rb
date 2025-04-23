# frozen_string_literal: true

module Castkit
  module Support
    module Attribute
      class << self
        def normalize_type(type)
          return type.map { |t| normalize_type(t) } if type.is_a?(Array)
          return type if Castkit.data_object?(type)

          resolve_type(type)
        end

        private

        def resolve_type(type)
          case type
          when Class
            return :boolean if [TrueClass, FalseClass].include?(type)

            type.name.downcase.to_sym
          when Symbol
            type
          else
            raise InvalidAttributeType.new(type: type)
          end
        end
      end
    end
  end
end
