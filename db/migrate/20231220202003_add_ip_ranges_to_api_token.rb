class AddIPRangesToAPIToken < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :authorized_networks, :inet, array: true, default: []
  end
end
