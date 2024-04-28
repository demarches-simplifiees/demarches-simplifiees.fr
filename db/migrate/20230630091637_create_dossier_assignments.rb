# frozen_string_literal: true

class CreateDossierAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :dossier_assignments do |t|
      t.references :dossier, foreign_key: true, null: false
      t.string :mode, null: false
      t.bigint :groupe_instructeur_id
      t.bigint :previous_groupe_instructeur_id
      t.string :groupe_instructeur_label
      t.string :previous_groupe_instructeur_label
      t.string :assigned_by
      t.timestamp :assigned_at, null: false
    end
  end
end
