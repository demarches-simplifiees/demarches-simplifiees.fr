class AddArchivedToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :archived, :boolean, default: false
  end
end
