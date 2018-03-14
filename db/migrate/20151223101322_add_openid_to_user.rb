class AddOpenidToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :france_connect_particulier_id, :string
  end
end
