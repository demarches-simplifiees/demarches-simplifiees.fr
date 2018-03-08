class DropNotifications < ActiveRecord::Migration[5.2]
  def change
    drop_table :notifications
  end
end
