# frozen_string_literal: true

class AddReasonToDossierCorrections < ActiveRecord::Migration[7.0]
  def change
    add_column :dossier_corrections, :reason, :string, default: 'incorrect', null: false
  end
end
