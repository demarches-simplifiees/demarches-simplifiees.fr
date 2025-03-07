# frozen_string_literal: true

class AddUnsubscribedToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email_unsubscribed, :boolean, default: false, null: false
  end
end
