# frozen_string_literal: true

class CreateRailsSimpleEventSourcingSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :rails_simple_event_sourcing_snapshots do |t|
      t.string :aggregate_type, null: false
      t.string :aggregate_id, null: false
      t.jsonb :state, null: false, default: {}
      t.integer :version, null: false
      t.string :schema_fingerprint

      t.timestamps
    end

    add_index :rails_simple_event_sourcing_snapshots,
              %i[aggregate_type aggregate_id],
              unique: true,
              name: 'index_snapshots_on_aggregate_type_and_aggregate_id'
  end
end
