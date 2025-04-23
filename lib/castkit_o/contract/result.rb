# frozen_string_literal: true

module Castkit
  module Contract
    # Represents the result of a contract validation.
    #
    # Provides access to the validation outcome, including whether it succeeded or failed,
    # and includes the full list of errors if any.
    class Result
      # @return [Symbol] the name of the contract
      attr_reader :contract

      # @return [Hash{Symbol => Object}] the validated input
      attr_reader :input

      # @return [Hash{Symbol => Object}] the validation error hash
      attr_reader :errors

      # Initializes a new result object.
      #
      # @param contract [Symbol, String] the name of the contract
      # @param input [Hash{Symbol => Object}] the validated input
      # @param errors [Hash{Symbol => Object}] the validation errors
      def initialize(contract, input, errors: {})
        @contract = contract.to_sym.freeze
        @input = input.freeze
        @errors = errors.freeze
      end

      # A debug-friendly representation of the validation result.
      #
      # @return [String]
      def inspect
        "#<#{self.class.name} contract=#{contract.inspect} success=#{success?} errors=#{errors.inspect}>"
      end

      # Whether the validation passed with no errors.
      #
      # @return [Boolean]
      def success?
        errors.empty?
      end

      # Whether the validation failed with one or more errors.
      #
      # @return [Boolean]
      def failure?
        !success?
      end

      # A readable string representation of the validation result.
      #
      # @return [String]
      def to_s
        return "[Castkit] Contract validation passed for #{contract}" if success?

        parsed_errors = errors.map { |k, v| "  #{k}: #{v.inspect}" }.join("\n")
        "[Castkit] Contract validation failed for #{contract}:\n#{parsed_errors}"
      end

      # @return [Hash{Symbol => Object}] the input validation and error hash
      def to_hash
        @to_hash ||= {
          contract: contract,
          input: input,
          errors: errors
        }.freeze
      end

      # @return [Hash{Symbol => Object}] the input and validation error hash
      alias to_h to_hash
    end
  end
end
