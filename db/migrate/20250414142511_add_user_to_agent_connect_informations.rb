# frozen_string_literal: true

class AddUserToAgentConnectInformations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :agent_connect_informations, :user, index: { algorithm: :concurrently }
  end
end
