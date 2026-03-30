# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Configuration
    attr_accessor :use_naming_convention_fallback, :events_per_page, :snapshot_interval

    def initialize
      @use_naming_convention_fallback = true
      @events_per_page = 25
      @snapshot_interval = nil
    end
  end
end
