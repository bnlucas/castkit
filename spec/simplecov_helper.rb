# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"
require "simplecov-html"

SimpleCov.formatters = [
  SimpleCov::Formatter::CoberturaFormatter,
  SimpleCov::Formatter::HTMLFormatter
]

SimpleCov.start do
  enable_coverage :branch

  track_files "lib/castkit/**/*.rb"

  add_filter "lib/castkit/version.rb"
  add_filter "/spec/"

  add_group "DataObjects", "lib/castkit/data_object"
  add_group "Attributes", "lib/castkit/attribute"
  add_group "Contracts", "lib/castkit/contract"
  add_group "Types", "lib/castkit/types"
  add_group "Plugins", "lib/castkit/plugins"
end

SimpleCov.minimum_coverage 100
