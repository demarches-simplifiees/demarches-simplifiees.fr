class AddStateToDossier < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :dossier_termine
    add_column :dossiers, :state, :string
  end
end
