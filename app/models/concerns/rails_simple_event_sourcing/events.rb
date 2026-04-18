# frozen_string_literal: true

module RailsSimpleEventSourcing
  module Events
    extend ActiveSupport::Concern
    include ReadOnly

    included do
      has_many :events, class_name: 'RailsSimpleEventSourcing::Event', as: :eventable,
                        dependent: :restrict_with_exception
    end

    def create_snapshot!
      latest_event = events.order(version: :desc).first
      return unless latest_event

      RailsSimpleEventSourcing::Snapshot.create_or_update!(
        aggregate_type: self.class.name,
        aggregate_id: id,
        state: attributes,
        version: latest_event.version,
        schema_fingerprint: RailsSimpleEventSourcing::Snapshot.fingerprint_for(self.class)
      )
    end
  end
end
