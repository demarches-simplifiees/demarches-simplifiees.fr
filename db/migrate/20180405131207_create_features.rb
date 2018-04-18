class CreateFeatures < ActiveRecord::Migration[5.2]
  def change
    create_table :flipflop_features do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps null: false
    end

    add_column :administrateurs, :features, :jsonb, null: false, default: {}
  end
end
