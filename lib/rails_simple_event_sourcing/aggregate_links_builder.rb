# frozen_string_literal: true

module RailsSimpleEventSourcing
  class AggregateLinksBuilder
    def initialize(data)
      @data = data
    end

    def call
      return {} if @data.blank?

      @data.filter_map { |key, value| entry_for(key.to_s, value) }.to_h
    end

    private

    def entry_for(key, value)
      return unless key.end_with?('_id') && value.present?

      klass = resolve_klass(key)
      return unless klass

      latest_event = Event.where(eventable_type: klass.name, aggregate_id: value.to_s).order(version: :desc).first
      return unless latest_event

      [key, { aggregate_type: klass.name, aggregate_id: value, event_id: latest_event.id }]
    end

    def resolve_klass(key)
      klass = key.delete_suffix('_id').camelize.safe_constantize
      return klass if event_sourced?(klass)

      event_sourced_classes.each do |source|
        assoc = source.reflect_on_all_associations(:belongs_to).find { |r| r.foreign_key.to_s == key }
        next unless assoc

        target = assoc.class_name.safe_constantize
        return target if event_sourced?(target)
      end

      nil
    end

    def event_sourced?(klass)
      klass&.ancestors&.include?(RailsSimpleEventSourcing::Events)
    end

    def event_sourced_classes
      @event_sourced_classes ||=
        Event.where.not(eventable_type: nil)
             .distinct.pluck(:eventable_type)
             .filter_map(&:safe_constantize)
             .select { |k| event_sourced?(k) }
    end
  end
end
