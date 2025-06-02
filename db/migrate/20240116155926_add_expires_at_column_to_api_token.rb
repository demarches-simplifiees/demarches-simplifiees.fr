# frozen_string_literal: true

class AddExpiresAtColumnToAPIToken < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :expires_at, :date
  end
end
