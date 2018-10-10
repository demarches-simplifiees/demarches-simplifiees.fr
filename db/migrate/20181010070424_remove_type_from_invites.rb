class RemoveTypeFromInvites < ActiveRecord::Migration[5.2]
  def change
    remove_column :invites, :type
  end
end
