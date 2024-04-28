# frozen_string_literal: true

class AddForeignKeysToDossierCorrections < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_foreign_key :dossier_corrections, :dossiers, column: :dossier_id, validate: false
    validate_foreign_key :dossier_corrections, :dossiers

    add_foreign_key :dossier_corrections, :commentaires, column: :commentaire_id, validate: false
    validate_foreign_key :dossier_corrections, :commentaires
  end
end
