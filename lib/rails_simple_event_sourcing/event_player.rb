# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventPlayer
    def initialize(event_class)
      @event_class = event_class
    end

    def replay_stream(aggregate_id, target_aggregate)
      events = load_event_stream(aggregate_id)
      apply_events(events, target_aggregate)
    end

    private

    def load_event_stream(aggregate_id)
      @event_class
        .where(aggregate_id:)
        .order(created_at: :asc)
    end

    def apply_events(events, aggregate)
      events.each do |event|
        event.apply(aggregate)
      end
    end
  end
end
