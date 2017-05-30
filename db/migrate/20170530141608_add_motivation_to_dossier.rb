class AddMotivationToDossier < ActiveRecord::Migration[5.0]
  def change
    add_column :dossiers, :motivation, :text
  end
end
