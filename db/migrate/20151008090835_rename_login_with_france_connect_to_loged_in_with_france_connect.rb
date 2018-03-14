class RenameLoginWithFranceConnectToLogedInWithFranceConnect < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :login_with_france_connect, :loged_in_with_france_connect
  end
end
