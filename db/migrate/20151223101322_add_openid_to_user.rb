class AddOpenidToUser < ActiveRecord::Migration
  def change
    add_column :users, :france_connect_particulier_id, :string
  end
end
