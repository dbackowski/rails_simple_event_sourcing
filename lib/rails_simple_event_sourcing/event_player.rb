# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventPlayer
    def initialize(aggregate)
      @aggregate = aggregate
    end

    def replay_and_apply(new_event)
      replay_stream unless @aggregate.new_record?
      new_event.apply(@aggregate)
    end

    def replay_stream(up_to_version: nil)
      events = load_event_stream(up_to_version:)
      apply_events(events)
    end

    private

    def load_event_stream(up_to_version:)
      scope = @aggregate.events.order(version: :asc)
      scope = scope.where(version: ..up_to_version) if up_to_version
      scope
    end

    def apply_events(events)
      events.each do |event|
        event.apply(@aggregate)
      end
    end
  end
end
