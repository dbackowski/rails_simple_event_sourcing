# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    include ReadOnly
    include EventAttributes
    include AggregateConfiguration

    belongs_to :eventable, polymorphic: true, optional: true
    alias aggregate eventable

    validates :version,
              presence: true,
              numericality: { only_integer: true, greater_than: 0 },
              if: -> { aggregate_id.present? }
    validates :version,
              uniqueness: { scope: :aggregate_id },
              if: -> { aggregate_id.present? }

    before_validation :setup_for_create, on: :create
    before_save :persist_aggregate, if: :aggregate_defined?
    after_create :disable_write_access!

    def apply(aggregate)
      payload.each do |key, value|
        raise "Unknown attribute '#{key}' on #{aggregate.class}" unless aggregate.respond_to?("#{key}=")

        aggregate.send("#{key}=", value)
      end
    end

    def aggregate_state
      return unless aggregate_defined? && aggregate_id.present?

      aggregate = aggregate_class.new
      aggregate.id = aggregate_id
      EventPlayer.new(aggregate).replay_stream(up_to_version: version)
      aggregate.attributes
    end

    private

    def setup_for_create
      setup_event_fields
      setup_aggregate if aggregate_defined?
      set_version
    end

    def setup_event_fields
      enable_write_access!
      self.event_type = self.class
      self.metadata = CurrentRequest.metadata&.compact&.presence
    end

    def setup_aggregate
      @aggregate = aggregate_repository.find_or_build(aggregate_id)
      @aggregate.enable_write_access!
      self.eventable = @aggregate
      EventPlayer.new(@aggregate).replay_and_apply(self)
    end

    def set_version
      return unless aggregate_defined?

      self.version ||= calculate_next_version
    end

    def calculate_next_version
      max_version = Event.where(aggregate_id:).maximum(:version) || 0
      max_version + 1
    end

    def persist_aggregate
      return unless @aggregate

      aggregate_repository.save!(@aggregate)
      self.aggregate_id = @aggregate.id
      @aggregate.disable_write_access!
    end

    def aggregate_repository
      @aggregate_repository ||= AggregateRepository.new(aggregate_class)
    end
  end
end
