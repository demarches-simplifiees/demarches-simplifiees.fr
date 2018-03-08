class AddTypeAttrInInviteTable < ActiveRecord::Migration[5.2]
  def change
    add_column :invites, :type, :string, default: 'InviteGestionnaire'
  end
end
