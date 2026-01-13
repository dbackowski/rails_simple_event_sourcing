# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventPlayer
    def initialize(aggregate)
      @aggregate = aggregate
    end

    def replay_stream
      events = load_event_stream
      apply_events(events)
    end

    private

    def load_event_stream
      @aggregate.events.order(version: :asc)
    end

    def apply_events(events)
      events.each do |event|
        event.apply(@aggregate)
      end
    end
  end
end
