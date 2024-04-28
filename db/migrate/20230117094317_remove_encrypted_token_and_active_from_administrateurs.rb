# frozen_string_literal: true

class RemoveEncryptedTokenAndActiveFromAdministrateurs < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_columns :administrateurs, :encrypted_token, :active }
  end
end
