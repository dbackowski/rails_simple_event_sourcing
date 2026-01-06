# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    include ReadOnly

    belongs_to :eventable, polymorphic: true, optional: true

    alias aggregate eventable

    after_initialize :initialize_event
    before_validation :enable_write_access_on_self, if: :new_record?
    before_validation :apply_on_aggregate, if: :aggregate_defined?
    before_save :add_metadata
    before_save :assign_aggregate_id_and_persist_aggregate, if: :aggregate_defined?

    def self.aggregate_model_name(name)
      singleton_class.instance_variable_set(:@aggregate_model_name, name)
    end

    def aggregate_model_name
      self.class.singleton_class.instance_variable_get(:@aggregate_model_name)
    end

    def self.event_attributes(*attributes)
      @event_attributes ||= []

      attributes.map(&:to_s).each do |attribute|
        define_method attribute do
          self.payload ||= {}
          self.payload[attribute]
        end

        define_method "#{attribute}=" do |argument|
          self.payload ||= {}
          self.payload[attribute] = argument
        end
      end

      @event_attributes
    end

    def apply(_aggregate)
      raise NoMethodError, "You must implement #{self.class}#apply"
    end

    private

    def aggregate_defined?
      aggregate_model_name.present?
    end

    def initialize_event
      self.class.prepend RailsSimpleEventSourcing::ApplyWithReturningAggregate
      @aggregate = find_or_build_aggregate if aggregate_defined?
      self.event_type = self.class
      self.eventable = @aggregate
    end

    def enable_write_access_on_self
      enable_write_access!
    end

    def apply_on_aggregate
      @aggregate.enable_write_access!
      apply_event_stream(@aggregate) unless @aggregate.new_record?
      apply(@aggregate)
    end

    def assign_aggregate_id_and_persist_aggregate
      @aggregate.save! if aggregate_id.present?
      self.aggregate_id = @aggregate.id
    end

    def add_metadata
      return if CurrentRequest.metadata.blank?

      self.metadata = CurrentRequest.metadata.compact.presence
    end

    def find_or_build_aggregate
      return aggregate_model_name.find(aggregate_id).lock! if aggregate_id.present?

      aggregate_model_name.new
    end

    def apply_event_stream(aggregate)
      events = self.class.where(aggregate_id:).order(created_at: :asc)
      events.each { |event| event.apply(aggregate) }
    end
  end
end
