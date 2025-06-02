# frozen_string_literal: true

class AddIPRangesToAPIToken < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :api_tokens, :authorized_networks, :inet, array: true, default: []
    end
  end
end
