# frozen_string_literal: true

class AddLastAuthenticatedAtToAPITokens < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :last_v1_authenticated_at, :datetime
    add_column :api_tokens, :last_v2_authenticated_at, :datetime
  end
end
