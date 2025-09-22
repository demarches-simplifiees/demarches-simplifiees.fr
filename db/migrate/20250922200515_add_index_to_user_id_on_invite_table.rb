# frozen_string_literal: true

class AddIndexToUserIdOnInviteTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :invites, :user_id, name: 'index_invites_on_user_id', algorithm: :concurrently
  end
end
