# frozen_string_literal: true

class CreateDossierPendingResponses < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :dossier_pending_responses do |t|
      t.references :dossier, null: false, foreign_key: false
      t.references :commentaire, foreign_key: false

      t.datetime :responded_at, precision: 6

      t.timestamps
    end

    add_index :dossier_pending_responses, :responded_at, algorithm: :concurrently

    add_foreign_key :dossier_pending_responses, :dossiers, column: :dossier_id, validate: false
    validate_foreign_key :dossier_pending_responses, :dossiers

    add_foreign_key :dossier_pending_responses, :commentaires, column: :commentaire_id, validate: false
    validate_foreign_key :dossier_pending_responses, :commentaires
  end
end
