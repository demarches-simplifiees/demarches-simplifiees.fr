# frozen_string_literal: true

class RemoveConstraintsFromFranceConnectInformation < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :france_connect_informations, :users
    change_column_null :france_connect_informations, :user_id, true
    change_column_null :france_connect_informations, :created_at, true
    change_column_null :france_connect_informations, :updated_at, true
  end
end
