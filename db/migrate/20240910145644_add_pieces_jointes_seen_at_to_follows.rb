# frozen_string_literal: true

class AddPiecesJointesSeenAtToFollows < ActiveRecord::Migration[7.0]
  def up
    add_column :follows, :pieces_jointes_seen_at, :datetime
    change_column_default :follows, :pieces_jointes_seen_at, from: nil, to: 'CURRENT_TIMESTAMP'
  end

  def down
    remove_column :follows, :pieces_jointes_seen_at
  end
end
