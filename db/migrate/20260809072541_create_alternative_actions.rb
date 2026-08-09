class CreateAlternativeActions < ActiveRecord::Migration[8.1]
  def change
    create_table :alternative_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :time_span, null: false, default: 0
      t.timestamps
    end
  end
end
