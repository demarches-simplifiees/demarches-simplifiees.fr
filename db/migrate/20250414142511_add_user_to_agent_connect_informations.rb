# frozen_string_literal: true

class AddUserToAgentConnectInformations < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_connect_informations, :user_id, :bigint, null: true, if_not_exists: true
  end
end
