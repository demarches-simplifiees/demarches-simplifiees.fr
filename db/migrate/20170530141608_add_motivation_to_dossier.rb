class AddMotivationToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :motivation, :text
  end
end
