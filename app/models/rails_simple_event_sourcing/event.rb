module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    belongs_to :eventable, polymorphic: true

    before_validation :apply_on_aggregate
    before_save :persist_aggregate
    after_initialize :initialize_event

    def self.aggregate_class_name(name)
      self.singleton_class.instance_variable_set(:@aggregate_class_name, name)
    end

    def aggregate_class_name
      self.class.singleton_class.instance_variable_get(:@aggregate_class_name)
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

    def apply
      raise NotImplementedError
    end

    private

    def initialize_event
      self.class.prepend RailsSimpleEventSourcing::ApplyWithReturningAggregate
      @aggregate = find_or_build_aggregate
      self.event_type = self.class
      self.eventable = @aggregate
    end

    def apply_on_aggregate
      apply(@aggregate)
    end

    def persist_aggregate
      @aggregate.save!
      self.aggregate_id = @aggregate.id
    end

    def find_or_build_aggregate
      return aggregate_class_name.find(aggregate_id) if aggregate_id.present?

      aggregate_class_name.new
    end
  end
end
