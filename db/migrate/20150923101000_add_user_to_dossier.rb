class AddUserToDossier < ActiveRecord::Migration[5.2]
  def change
    add_reference :dossiers, :user, index: true
    add_foreign_key :dossiers, :users
  end
end
