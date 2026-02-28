# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Result
    attr_reader :data, :errors

    def initialize(success:, data: nil, errors: nil)
      @success = success
      @data    = data
      @errors  = errors
    end

    def success?
      @success
    end

    def on_success(&block)
      block.call(data) if success?
      self
    end

    def on_failure(&block)
      block.call(errors) unless success?
      self
    end
  end
end
