# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
  add_group "DataObjects", "lib/castkit/data_object"
  add_group "Attributes", "lib/castkit/attribute"
  add_group "Contracts", "lib/castkit/contract"
  add_group "Types", "lib/castkit/types"
  add_group "Plugins", "lib/castkit/plugins"
end

SimpleCov.minimum_coverage 90

require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
