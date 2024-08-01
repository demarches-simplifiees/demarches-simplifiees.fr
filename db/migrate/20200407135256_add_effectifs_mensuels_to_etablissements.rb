# frozen_string_literal: true

class AddEffectifsMensuelsToEtablissements < ActiveRecord::Migration[5.2]
  def change
    add_column :etablissements, :effectif_mois, :string
    add_column :etablissements, :effectif_annee, :string
    add_column :etablissements, :effectif_mensuel, :decimal
  end
end
