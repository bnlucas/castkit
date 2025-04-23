# frozen_string_literal: true

require "thor"
require_relative "cli/main"

module Castkit
  # Entrypoint for Castkit’s command-line interface.
  #
  # Delegates to the `Castkit::CLI::Main` Thor class, which defines all CLI commands.
  #
  # @example Executing from a binstub
  #   Castkit::CLI.start(ARGV)
  #
  module CLI
    # Starts the Castkit CLI.
    #
    # @param args [Array<String>] the command-line arguments
    # @param kwargs [Hash] additional keyword arguments passed to Thor
    # @return [void]
    def self.start(*args, **kwargs)
      Castkit::CLI::Main.start(*args, **kwargs)
    end
  end
end
