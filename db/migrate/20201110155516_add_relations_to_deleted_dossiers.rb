# frozen_string_literal: true

class AddRelationsToDeletedDossiers < ActiveRecord::Migration[6.0]
  def change
    add_column :deleted_dossiers, :user_id, :bigint
    add_column :deleted_dossiers, :groupe_instructeur_id, :bigint
    add_column :deleted_dossiers, :revision_id, :bigint
  end
end
