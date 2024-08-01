# frozen_string_literal: true

class AddExpiredNotificationSentAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :inactive_close_to_expiration_notice_sent_at, :datetime, precision: 6, null: true
  end
end
