# frozen_string_literal: true

class AddAnnouncesSeenAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :announces_seen_at, :datetime, null: true, default: nil, precision: 6
  end
end
