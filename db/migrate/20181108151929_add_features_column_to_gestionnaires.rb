class AddFeaturesColumnToGestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :gestionnaires, :features, :jsonb, null: false, default: {}
  end
end
