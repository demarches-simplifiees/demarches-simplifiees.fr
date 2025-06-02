# frozen_string_literal: true

class CreateCommentaireGroupeGestionnaires < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table "commentaire_groupe_gestionnaires" do |t|
      t.references :groupe_gestionnaire, index: { name: :index_commentaire_groupe_gestionnaires_on_groupe_gestionnaire }
      t.references "gestionnaire", null: true
      t.string "sender_type", null: false
      t.bigint "sender_id", null: false
      t.string "body"
      t.datetime "discarded_at"
      t.timestamps
    end
  end
end
