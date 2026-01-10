# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    prepend ApplyWithReturningAggregate
    include ReadOnly
    include EventAttributes
    include AggregateConfiguration

    belongs_to :eventable, polymorphic: true, optional: true
    alias aggregate eventable

    # Callbacks for automatic aggregate lifecycle
    before_validation :setup_event_fields, on: :create
    before_validation :apply_event_to_aggregate, on: :create, if: :aggregate_defined?
    before_save :persist_aggregate, if: :aggregate_defined?

    # Must be implemented by subclasses
    def apply(_aggregate)
      raise NotImplementedError, "#{self.class}#apply must be implemented"
    end

    private

    def setup_event_fields
      enable_write_access!
      self.event_type = self.class
      self.metadata = CurrentRequest.metadata&.compact&.presence
    end

    def apply_event_to_aggregate
      @aggregate_for_persistence = aggregate_repository.find_or_build(aggregate_id)
      self.eventable = @aggregate_for_persistence

      applicator = EventApplicator.new(self)
      applicator.apply_to_aggregate(@aggregate_for_persistence)
    end

    def persist_aggregate
      return unless @aggregate_for_persistence

      aggregate_repository.save!(@aggregate_for_persistence) if aggregate_id.present?
      self.aggregate_id = @aggregate_for_persistence.id
    end

    def aggregate_repository
      @aggregate_repository ||= AggregateRepository.new(aggregate_class)
    end
  end
end
