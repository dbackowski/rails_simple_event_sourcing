# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Configuration
    attr_accessor :use_naming_convention_fallback, :events_per_page
    attr_reader :snapshot_interval

    def initialize
      @use_naming_convention_fallback = true
      @events_per_page = 25
      @snapshot_interval = nil
    end

    def snapshot_interval=(value)
      if !value.nil? && !(value.is_a?(Integer) && value.positive?)
        raise ArgumentError,
              "snapshot_interval must be nil or a positive integer, got #{value.inspect}"
      end

      @snapshot_interval = value
    end
  end
end
