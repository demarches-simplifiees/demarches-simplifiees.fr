# frozen_string_literal: true

class AddAgentConnectIdTokenColumnToInstructeurTable < ActiveRecord::Migration[7.0]
  def change
    add_column :instructeurs, :agent_connect_id_token, :string
  end
end
