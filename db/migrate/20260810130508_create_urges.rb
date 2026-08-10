class CreateUrges < ActiveRecord::Migration[8.1]
  def change
    create_table :urges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :alternative_action, null: true, foreign_key: { on_delete: :nullify }
      t.integer :resolved, null: false, default: 0
      t.integer :trigger, null: true
      t.text :memo
      t.timestamps
    end
  end
end
