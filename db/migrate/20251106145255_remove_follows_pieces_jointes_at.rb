# frozen_string_literal: true

class RemoveFollowsPiecesJointesAt < ActiveRecord::Migration[7.2]
  def change
    safety_assured { remove_column :follows, :pieces_jointes_seen_at }
  end
end
