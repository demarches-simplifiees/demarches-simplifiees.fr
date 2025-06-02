# frozen_string_literal: true

class AddBlockedAtBlockReasontoUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :blocked_at, :datetime
    add_column :users, :blocked_reason, :text
  end
end
