# frozen_string_literal: true

class CreateDossierLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :dossier_labels do |t|
      t.references :dossier, null: false, foreign_key: true
      t.references :procedure_label, null: false, foreign_key: true

      t.timestamps
    end
  end
end
