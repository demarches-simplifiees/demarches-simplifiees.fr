# frozen_string_literal: true

class AddAmrColumnToAgentConnectInformationsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :agent_connect_informations, :amr, :string, array: true, default: []
  end
end
