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
      snapshot = load_snapshot(up_to_version:)

      if snapshot
        restore_from_snapshot(snapshot)
        from_version = snapshot.version + 1
      else
        from_version = 1
      end

      scope = @aggregate.events.where(version: from_version..)
      scope = scope.where(version: ..up_to_version).order(:version) if up_to_version
      scope
    end

    def load_snapshot(up_to_version:)
      return nil if @aggregate.new_record?

      snapshot = Snapshot.find_by(
        aggregate_type: @aggregate.class.name,
        aggregate_id: @aggregate.id.to_s
      )
      return nil if snapshot && up_to_version && snapshot.version > up_to_version

      snapshot
    end

    def restore_from_snapshot(snapshot)
      snapshot.state.each do |key, value|
        @aggregate.send("#{key}=", value) if @aggregate.respond_to?("#{key}=")
      end
    end

    def apply_events(events)
      events.each do |event|
        event.apply(@aggregate)
      end
    end
  end
end
