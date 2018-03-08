class AddFranceConnectParticulierAttributsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :gender, :string
    add_column :users, :given_name, :string
    add_column :users, :family_name, :string
    add_column :users, :birthdate, :date
    add_column :users, :birthplace, :string
  end
end
