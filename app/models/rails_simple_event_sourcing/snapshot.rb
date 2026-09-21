# frozen_string_literal: true

module RailsSimpleEventSourcing
  class Snapshot < ApplicationRecord
    # No model validations: every write goes through create_or_update! below, which
    # bypasses ActiveRecord entirely. The NOT NULL constraints in the migration are
    # what actually enforce presence.
    def self.create_from_event!(event)
      create_or_update!(
        aggregate_type: event.eventable_type,
        aggregate_id: event.aggregate_id,
        state: event.eventable.attributes,
        version: event.version,
        schema_fingerprint: fingerprint_for(event.eventable.class)
      )
    end

    def self.create_or_update!(aggregate_type:, aggregate_id:, state:, version:, schema_fingerprint:) # rubocop:disable Metrics/MethodLength, Naming/PredicateMethod
      now = Time.current
      sql = sanitize_sql_array(
        [
          <<~SQL.squish,
            INSERT INTO rails_simple_event_sourcing_snapshots
              (aggregate_type, aggregate_id, state, version, schema_fingerprint, created_at, updated_at)
            VALUES (?, ?, ?::jsonb, ?, ?, ?, ?)
            ON CONFLICT (aggregate_type, aggregate_id)
            DO UPDATE SET
              state = EXCLUDED.state,
              version = EXCLUDED.version,
              schema_fingerprint = EXCLUDED.schema_fingerprint,
              updated_at = EXCLUDED.updated_at
            WHERE rails_simple_event_sourcing_snapshots.version <= EXCLUDED.version
          SQL
          aggregate_type,
          aggregate_id,
          state.to_json,
          version,
          schema_fingerprint,
          now,
          now
        ]
      )
      # DO UPDATE is skipped when a newer snapshot already exists, so report whether
      # a row was actually written rather than leaking the driver result.
      connection.execute(sql).cmd_tuples.positive?
    end

    def self.fingerprint_for(aggregate_class)
      signature = aggregate_class.columns
                                 .map { |c| "#{c.name}:#{c.sql_type}:#{c.null}" }
                                 .sort
                                 .join(',')
      Digest::SHA256.hexdigest(signature)
    end
  end
end
