# frozen_string_literal: true

class AddEntrepriseEtatAdministratifToEtablissements < ActiveRecord::Migration[6.1]
  def change
    add_column :etablissements, :entreprise_etat_administratif, :string
  end
end
