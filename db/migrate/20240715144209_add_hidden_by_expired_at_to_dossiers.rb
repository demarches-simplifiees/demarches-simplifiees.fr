class AddHiddenByExpiredAtToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :hidden_by_expired_at, :datetime
  end
end
