class AddUniqueIndexToInvite < ActiveRecord::Migration[6.0]
  def change
    add_index :invites, [:email, :dossier_id], unique: true
  end
end
