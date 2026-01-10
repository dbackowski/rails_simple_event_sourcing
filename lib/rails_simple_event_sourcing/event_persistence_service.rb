# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventPersistenceService
    def initialize(event)
      @event = event
      @aggregate = nil
    end

    def save!
      ActiveRecord::Base.transaction do
        prepare_event
        load_aggregate
        apply_event_to_aggregate
        enrich_metadata
        persist_both
      end
    end

    private

    def prepare_event
      @event.class.prepend ApplyWithReturningAggregate
      @event.enable_write_access!
      @event.event_type = @event.class
    end

    def load_aggregate
      return unless aggregate_defined?

      @aggregate = aggregate_repository.find_or_build(@event.aggregate_id)
      @event.eventable = @aggregate
    end

    def apply_event_to_aggregate
      return unless aggregate_defined?

      applicator = EventApplicator.new(@event)
      applicator.apply_to_aggregate(@aggregate)
    end

    def enrich_metadata
      @event.metadata = CurrentRequest.metadata&.compact&.presence
    end

    def persist_both
      return unless aggregate_defined?

      save_event
      save_aggregate
    end

    def save_event
      # Mark the event as being saved by the service to avoid re-entrance
      @event.instance_variable_set(:@saving_from_service, true)
      @event.save!
    ensure
      @event.instance_variable_set(:@saving_from_service, false)
    end

    def save_aggregate
      aggregate_repository.save!(@aggregate) if @event.aggregate_id.present?
      @event.aggregate_id = @aggregate.id
    end

    def aggregate_defined?
      @event.aggregate_defined?
    end

    def aggregate_repository
      @aggregate_repository ||= AggregateRepository.new(@event.aggregate_model_class_name)
    end
  end
end
