# frozen_string_literal: true

class RemoveDossierCorrectionsKind < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :dossier_corrections, :kind, :string, default: 'incorrect', null: false
    end
  end
end
