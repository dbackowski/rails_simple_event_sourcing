# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    prepend ApplyWithReturningAggregate
    include ReadOnly
    include EventAttributes
    include AggregateConfiguration

    belongs_to :eventable, polymorphic: true, optional: true
    alias aggregate eventable

    # Validations
    validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :version, uniqueness: { scope: :aggregate_id }, if: -> { aggregate_id.present? }

    # Callbacks for automatic aggregate lifecycle
    before_validation :setup_event_fields, on: :create
    before_validation :set_version
    before_validation :apply_event_to_aggregate, on: :create, if: :aggregate_defined?
    before_save :persist_aggregate, if: :aggregate_defined?

    def apply(aggregate)
      payload.each do |key, value|
        aggregate.send("#{key}=", value) if aggregate.respond_to?("#{key}=")
      end
      aggregate
    end

    private

    def setup_event_fields
      enable_write_access!
      self.event_type = self.class
      self.metadata = CurrentRequest.metadata&.compact&.presence
    end

    def set_version
      self.version ||= calculate_next_version
    end

    def calculate_next_version
      return 1 unless aggregate_id

      max_version = Event.where(aggregate_id:).maximum(:version) || 0
      max_version + 1
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
