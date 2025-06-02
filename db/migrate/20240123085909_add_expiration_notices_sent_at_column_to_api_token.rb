# frozen_string_literal: true

class AddExpirationNoticesSentAtColumnToAPIToken < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :api_tokens, :expiration_notices_sent_at, :date, array: true, default: []
    end
  end
end
