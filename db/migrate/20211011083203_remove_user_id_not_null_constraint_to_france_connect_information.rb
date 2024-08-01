# frozen_string_literal: true

class RemoveUserIdNotNullConstraintToFranceConnectInformation < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:france_connect_informations, :user_id, true)
  end
end
