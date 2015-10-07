class AddLoginWithFranceConnectToUser < ActiveRecord::Migration
  def change
    add_column :users, :login_with_france_connect, :boolean, :default => false
  end
end
