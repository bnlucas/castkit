# frozen_string_literal: true

module Castkit
  class << self
    def data_object?(obj)
      obj.is_a?(Class) && (
        obj <= Castkit::DataObject ||
          obj.ancestors.include?(Castkit::DSL::DataObject)
      )
    end
  end
end

require_relative "castkit/attribute"
