class AddTypeAttrInInviteTable < ActiveRecord::Migration
  def change
    add_column :invites, :type, :string, default: 'InviteGestionnaire'
  end
end
