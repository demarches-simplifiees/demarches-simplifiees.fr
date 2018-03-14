class RemoveDefaultDateToDossier < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:dossiers, :created_at, nil)
    change_column_default(:dossiers, :updated_at, nil)
  end
end
