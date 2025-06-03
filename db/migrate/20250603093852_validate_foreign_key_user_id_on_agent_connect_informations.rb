# frozen_string_literal: true

class ValidateForeignKeyUserIdOnAgentConnectInformations < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :agent_connect_informations, :users
  end
end
