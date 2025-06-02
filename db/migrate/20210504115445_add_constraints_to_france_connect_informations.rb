# frozen_string_literal: true

class AddConstraintsToFranceConnectInformations < ActiveRecord::Migration[6.1]
  def change
    change_column_null :france_connect_informations, :user_id, false
    change_column_null :france_connect_informations, :created_at, false
    change_column_null :france_connect_informations, :updated_at, false
    add_foreign_key :france_connect_informations, :users
  end
end
