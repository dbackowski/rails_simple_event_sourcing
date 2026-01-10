# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventApplicator
    def initialize(event)
      @event = event
    end

    def apply_to_aggregate(aggregate)
      enable_aggregate_writes(aggregate)
      replay_history_if_needed(aggregate)
      apply_current_event(aggregate)
    end

    private

    def enable_aggregate_writes(aggregate)
      aggregate.enable_write_access!
    end

    def replay_history_if_needed(aggregate)
      return if aggregate.new_record?

      player = EventPlayer.new(aggregate)
      player.replay_stream
    end

    def apply_current_event(aggregate)
      @event.apply(aggregate)
    end
  end
end
