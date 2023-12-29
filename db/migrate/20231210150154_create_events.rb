class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :event_type, null: false
      t.string :aggregate_id
      t.references :eventable, polymorphic: true
      t.jsonb :payload
      t.jsonb :metadata

      t.timestamps
    end
  end
end
