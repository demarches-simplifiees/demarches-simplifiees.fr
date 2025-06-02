# frozen_string_literal: true

class AddLastUsedIpsColumnToAPIToken < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :api_tokens, :stored_ips, :inet, array: true, default: []
    end
  end
end
