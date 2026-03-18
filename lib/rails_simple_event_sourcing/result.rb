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

    def failure?
      !@success
    end

    def on_success
      raise ArgumentError, 'Block required' unless block_given?

      yield data if success?
      self
    end

    def on_failure
      raise ArgumentError, 'Block required' unless block_given?

      yield errors unless success?
      self
    end
  end
end
