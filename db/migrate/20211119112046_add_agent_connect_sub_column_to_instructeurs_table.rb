# frozen_string_literal: true

class AddAgentConnectSubColumnToInstructeursTable < ActiveRecord::Migration[6.1]
  def change
    add_column :instructeurs, :agent_connect_id, :string
    add_index :instructeurs, :agent_connect_id, unique: true
  end
end
