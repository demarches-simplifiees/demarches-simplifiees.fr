# frozen_string_literal: true

class AddKindToDossierCorrections < ActiveRecord::Migration[7.0]
  def change
    add_column :dossier_corrections, :kind, :string, default: 'correction', null: false
  end
end
