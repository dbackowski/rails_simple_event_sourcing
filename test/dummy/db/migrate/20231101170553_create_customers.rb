class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.timestamp :deleted_at

      t.timestamps
      t.index :email, unique: true
    end
  end
end
