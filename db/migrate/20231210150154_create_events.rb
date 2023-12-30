class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :type, null: false
      t.string :event_type, null: false
      t.string :aggregate_id
      t.references :eventable, polymorphic: true
      t.jsonb :payload
      t.jsonb :metadata

      t.timestamps

      t.index :type
      t.index :event_type
      t.index :aggregate_id
    end
  end
end
