class AddStateToDossier < ActiveRecord::Migration
  def change
    remove_column :dossiers, :dossier_termine
    add_column :dossiers, :state, :string
  end
end
