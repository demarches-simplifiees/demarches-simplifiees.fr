# frozen_string_literal: true

class AddIndexOnAgentConnectInformationsUserId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :agent_connect_informations, :user_id, algorithm: :concurrently, if_not_exists: true
  end
end
