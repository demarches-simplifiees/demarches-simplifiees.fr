class AddArchivedToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :archived, :boolean, default: false
  end
end
