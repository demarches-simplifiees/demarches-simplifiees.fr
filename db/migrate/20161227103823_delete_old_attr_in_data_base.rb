class DeleteOldAttrInDataBase < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :nom_projet
    remove_column :procedures, :test
    remove_column :notifications, :multiple
  end
end
