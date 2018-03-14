class ChangeTypeOfLogedInWithFranceConnectToUser < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :loged_in_with_france_connect, :string
  end
end
