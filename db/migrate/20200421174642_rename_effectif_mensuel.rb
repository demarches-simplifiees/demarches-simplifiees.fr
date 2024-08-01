# frozen_string_literal: true

class RenameEffectifMensuel < ActiveRecord::Migration[5.2]
  def change
    rename_column :etablissements, :effectif_mensuel, :entreprise_effectif_mensuel
    rename_column :etablissements, :effectif_mois, :entreprise_effectif_mois
    rename_column :etablissements, :effectif_annee, :entreprise_effectif_annee
  end
end
