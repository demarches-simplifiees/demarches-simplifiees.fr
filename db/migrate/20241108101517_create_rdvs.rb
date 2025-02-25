# frozen_string_literal: true

class CreateRdvs < ActiveRecord::Migration[7.0]
  def change
    create_table :rdvs do |t|
      t.string :status
      t.string :rdv_external_id
      t.string :rdv_plan_external_id, null: false
      t.datetime :starts_at
      t.references :dossier, null: false, foreign_key: true
      t.references :instructeur, null: false, foreign_key: true

      t.timestamps
    end

    add_index :rdvs, [:dossier_id, :starts_at]
    add_index :rdvs, [:dossier_id, :rdv_external_id]
  end
end
