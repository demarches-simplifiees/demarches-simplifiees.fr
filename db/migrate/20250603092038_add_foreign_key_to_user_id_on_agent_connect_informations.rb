# frozen_string_literal: true

class AddForeignKeyToUserIdOnAgentConnectInformations < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :agent_connect_informations, :users, validate: false
  end
end
