# frozen_string_literal: true

class AddEffectifAnneeAnterieure < ActiveRecord::Migration[5.2]
  def change
    add_column :etablissements, :entreprise_effectif_annuel, :decimal
    add_column :etablissements, :entreprise_effectif_annuel_annee, :string
  end
end
