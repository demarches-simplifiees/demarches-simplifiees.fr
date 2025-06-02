# frozen_string_literal: true

class AddMessageIdToEmailEvent < ActiveRecord::Migration[6.1]
  def change
    add_column :email_events, :message_id, :string
  end
end
