module RailsSimpleEventSourcing
  class Event < ApplicationRecord
    belongs_to :eventable, polymorphic: true, optional: true

    after_initialize :initialize_event
    before_validation :apply_on_aggregate, if: :aggregate_defined?
    before_save :add_metadata
    before_save :persist_aggregate, if: :aggregate_defined?

    def self.aggregate_model_name(name)
      self.singleton_class.instance_variable_set(:@aggregate_model_name, name)
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

    def apply
      raise NotImplementedError
    end

    private

    def aggregate_defined?
      aggregate_model_name.present?
    end

    def event_metadata
      {
        request_id: CurrentRequest.request_id,
        request_user_agent: CurrentRequest.request_user_agent,
        request_referer: CurrentRequest.request_referer,
        request_ip: CurrentRequest.request_ip,
        request_params: CurrentRequest.request_params
      }
    end

    def initialize_event
      self.class.prepend RailsSimpleEventSourcing::ApplyWithReturningAggregate
      @aggregate = find_or_build_aggregate if aggregate_defined? && eventable_type.present?
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

    def add_metadata
      self.metadata = event_metadata.compact.presence
    end

    def find_or_build_aggregate
      return aggregate_model_name.find(aggregate_id) if aggregate_id.present?

      aggregate_model_name.new
    end
  end
end
