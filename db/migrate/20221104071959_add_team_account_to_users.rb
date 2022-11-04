class AddTeamAccountToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :team_account, :boolean
    change_column_default :users, :team_account, false
  end
end
