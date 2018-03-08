class AddLoginWithFranceConnectToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :login_with_france_connect, :boolean, :default => false
  end
end
