# frozen_string_literal: true

class AddEmailsToCommentaireGroupeGestionnaires < ActiveRecord::Migration[6.1]
  def change
    # in case sender or gestionnaire would have been deleted
    add_column :commentaire_groupe_gestionnaires, :sender_email, :string
    add_column :commentaire_groupe_gestionnaires, :gestionnaire_email, :string
  end
end
