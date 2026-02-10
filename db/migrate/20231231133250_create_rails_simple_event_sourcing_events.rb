# frozen_string_literal: true

class CreateRailsSimpleEventSourcingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :rails_simple_event_sourcing_events do |t|
      t.references :eventable, polymorphic: true
      t.string :type, null: false
      t.string :event_type, null: false
      t.string :aggregate_id
      t.integer :version, null: false
      t.jsonb :payload
      t.jsonb :metadata

      t.timestamps

      t.index :type
      t.index :event_type
      t.index %i[aggregate_id version], unique: true, name: 'index_events_on_aggregate_id_and_version'
      t.index :payload, using: :gin
      t.index :metadata, using: :gin
    end
  end
end
