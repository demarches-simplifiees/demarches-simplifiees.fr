class AddTimestampsToEntreprise < ActiveRecord::Migration[5.0]
  def change
    add_column :entreprises, :created_at, :datetime
    add_column :entreprises, :updated_at, :datetime
  end
end
