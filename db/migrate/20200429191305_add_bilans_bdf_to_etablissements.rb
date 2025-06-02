# frozen_string_literal: true

class AddBilansBdfToEtablissements < ActiveRecord::Migration[5.2]
  def change
    add_column :etablissements, :entreprise_bilans_bdf, :jsonb
    add_column :etablissements, :entreprise_bilans_bdf_monnaie, :string
  end
end
