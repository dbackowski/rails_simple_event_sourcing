# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    prepend ApplyWithReturningAggregate
    include ReadOnly
    include EventAttributes
    include AggregateConfiguration

    belongs_to :eventable, polymorphic: true, optional: true
    alias aggregate eventable

    after_initialize :setup_event
    before_validation :enable_write_access_on_self, if: :new_record?
    before_validation :apply_to_aggregate, if: :aggregate_defined?
    before_save :enrich_metadata
    before_save :persist_aggregate, if: :aggregate_defined?

    # Must be implemented by subclasses
    def apply(_aggregate)
      raise NotImplementedError, "#{self.class}#apply must be implemented"
    end

    private

    def setup_event
      load_aggregate if aggregate_defined?
      self.event_type = self.class
      self.eventable = @aggregate
    end

    def load_aggregate
      @aggregate = aggregate_repository.find_or_build(aggregate_id)
    end

    def apply_to_aggregate
      applicator = EventApplicator.new(self)
      applicator.apply_to_aggregate(@aggregate)
    end

    def persist_aggregate
      aggregate_repository.save!(@aggregate) if aggregate_id.present?
      self.aggregate_id = @aggregate.id
    end

    def enrich_metadata
      self.metadata = CurrentRequest.metadata&.compact&.presence
    end

    def enable_write_access_on_self
      enable_write_access!
    end

    def aggregate_repository
      @aggregate_repository ||= AggregateRepository.new(aggregate_model_class)
    end
  end
end
