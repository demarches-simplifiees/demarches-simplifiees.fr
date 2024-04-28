# frozen_string_literal: true

class AddTokenColumnsToFranceConnectInformation < ActiveRecord::Migration[6.1]
  def change
    add_column :france_connect_informations, :merge_token, :string
    add_column :france_connect_informations, :merge_token_created_at, :datetime

    add_index :france_connect_informations, :merge_token
  end
end
