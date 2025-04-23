# frozen_string_literal: true

require_relative "lib/castkit_o/version"

Gem::Specification.new do |spec|
  spec.name          = "castkit"
  spec.version       = Castkit::VERSION
  spec.authors       = ["Nathan Lucas"]
  spec.email         = ["bnlucas@outlook.com"]

  spec.summary       = "Type-safe, validated data objects for Ruby"
  spec.description   = "Castkit is a lightweight, type-safe Ruby DSL for defining, validating, and serializing " \
                       "structured data objects. Inspired by DTO patterns, it supports nested types, access " \
                       "control, custom serializers, and more."
  spec.homepage      = "https://github.com/bnlucas/castkit"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = "https://github.com/bnlucas/castkit"
  spec.metadata["changelog_uri"]    = "https://github.com/bnlucas/castkit/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "cattri", "~> 0.1", ">= 0.1.2"
  spec.add_dependency "thor"

  # Development dependencies
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-cobertura"
  spec.add_development_dependency "simplecov-html"
  spec.add_development_dependency "yard"
end
