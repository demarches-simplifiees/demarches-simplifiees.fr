# frozen_string_literal: true

class BackfillFollowsWithPiecesJointesSeenAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    Follow.in_batches do |relation|
      relation.update_all pieces_jointes_seen_at: Time.zone.now
      sleep(0.001) # throttle
    end
  end

  def down
  end
end
