# frozen_string_literal: true

class CreateRailsSimpleEventSourcingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :rails_simple_event_sourcing_events do |t|
      t.references :eventable, polymorphic: true
      t.string :type, null: false
      t.string :aggregate_id
      t.bigint :version
      t.jsonb :payload
      t.jsonb :metadata

      t.timestamps

      t.index :type
      t.index %i[eventable_type aggregate_id version],
              unique: true,
              name: 'index_events_on_eventable_type_and_aggregate_id_and_version'
      t.index :payload, using: :gin
      t.index :metadata, using: :gin
    end
  end
end
