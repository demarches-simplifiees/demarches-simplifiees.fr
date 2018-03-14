class AddStateDatesToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :initiated_at, :datetime
    add_column :dossiers, :received_at, :datetime
    add_column :dossiers, :processed_at, :datetime
  end
end
