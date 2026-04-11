# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Snapshot < ApplicationRecord
    validates :aggregate_type, :aggregate_id, :state, :version, presence: true

    def self.create_from_event!(event)
      create_or_update!(
        aggregate_type: event.eventable_type,
        aggregate_id: event.aggregate_id,
        state: event.eventable.attributes,
        version: event.version,
        schema_fingerprint: fingerprint_for(event.eventable.class)
      )
    end

    def self.create_or_update!(aggregate_type:, aggregate_id:, state:, version:, schema_fingerprint:)
      upsert( # rubocop:disable Rails/SkipsModelValidations
        {
          aggregate_type: aggregate_type,
          aggregate_id: aggregate_id.to_s,
          state: state,
          version: version,
          schema_fingerprint: schema_fingerprint
        },
        unique_by: :index_snapshots_on_aggregate_type_and_aggregate_id
      )
    end

    def self.fingerprint_for(aggregate_class)
      Digest::SHA256.hexdigest(aggregate_class.column_names.sort.join(','))
    end
  end
end
