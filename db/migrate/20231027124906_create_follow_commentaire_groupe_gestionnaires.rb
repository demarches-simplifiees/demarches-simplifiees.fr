# frozen_string_literal: true

class CreateFollowCommentaireGroupeGestionnaires < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table "follow_commentaire_groupe_gestionnaires" do |t|
      t.references :groupe_gestionnaire, index: { name: :index_follow_commentaire_on_groupe_gestionnaire }
      t.references :gestionnaire, null: false, index: { name: :index_follow_commentaire_on_gestionnaire }
      t.string "sender_type", null: true
      t.bigint "sender_id", null: true
      t.datetime "commentaire_seen_at"
      t.datetime "unfollowed_at"
      t.timestamps
      t.index [:gestionnaire_id, :groupe_gestionnaire_id, :sender_id, :sender_type, :unfollowed_at], name: :index_follow_commentaire_on_groupe_gestionnaire_unfollow, unique: true
    end
  end
end
