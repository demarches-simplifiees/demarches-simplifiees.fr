class AddMessageToInvites < ActiveRecord::Migration[5.2]
  def change
    add_column :invites, :message, :text
  end
end
