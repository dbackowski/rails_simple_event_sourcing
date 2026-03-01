# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Result
    attr_reader :data, :errors

    def self.success(data: nil)
      new(success: true, data:)
    end

    def self.failure(errors:)
      new(success: false, errors:)
    end

    def initialize(success:, data: nil, errors: nil)
      raise ArgumentError, 'Successful result cannot have errors' if success && errors
      raise ArgumentError, 'Failed result cannot have data' if !success && data

      @success = success
      @data    = data
      @errors  = errors
    end

    def success?
      @success
    end

    def on_success(&block)
      raise ArgumentError, 'Block required' unless block

      block.call(data) if success?
      self
    end

    def on_failure(&block)
      raise ArgumentError, 'Block required' unless block

      block.call(errors) unless success?
      self
    end
  end
end
