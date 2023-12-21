class AddLastUsedIpsColumnToAPIToken < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :stored_ips, :inet, array: true, default: []
  end
end
