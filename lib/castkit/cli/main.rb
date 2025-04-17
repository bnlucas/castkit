# frozen_string_literal: true

require_relative "generate"
require_relative "list"

module Castkit
  module CLI
    # Main CLI entry point for Castkit.
    #
    # Provides top-level commands for printing the gem version and generating Castkit components.
    #
    # @example Print the version
    #   $ castkit version
    #
    # @example Generate a DataObject
    #   $ castkit generate dataobject User name:string age:integer
    class Main < Thor
      desc "version", "Prints the version"
      # Outputs the current Castkit version.
      #
      # @return [void]
      def version
        puts Castkit::VERSION
      end

      desc "generate TYPE NAME", "Generate a Castkit component"
      # Dispatches to the `castkit generate` subcommands.
      #
      # Supports generating components like `type`, `dataobject`, `contract`, etc.
      #
      # @return [void]
      subcommand "generate", Castkit::CLI::Generate

      desc "list COMPONENT", "List registered Castkit components"
      # Dispatches to the `castkit list` subcommands.
      #
      # Supports listing components like `type`, `dataobject`, `contract`, etc.
      #
      # @return [void]
      subcommand "list", Castkit::CLI::List
    end
  end
end
