# frozen_string_literal: true

class CreateDossierTransfers < ActiveRecord::Migration[6.1]
  def change
    create_table :dossier_transfers do |t|
      t.string :email, null: false, index: true

      t.timestamps
    end

    add_reference :dossiers, :dossier_transfer, foreign_key: true, null: true, index: true
  end
end
