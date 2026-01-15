# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Configuration
    attr_accessor :use_naming_convention_fallback

    def initialize
      @use_naming_convention_fallback = true
    end
  end
end
