class AddUnconfirmedEmailColumnToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unconfirmed_email, :text
  end
end
