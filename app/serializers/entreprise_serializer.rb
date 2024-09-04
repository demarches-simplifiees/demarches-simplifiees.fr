# frozen_string_literal: true

class EntrepriseSerializer < ActiveModel::Serializer
  attributes :siren,
    :capital_social,
    :numero_tva_intracommunautaire,
    :forme_juridique,
    :forme_juridique_code,
    :nom_commercial,
    :raison_sociale,
    :siret_siege_social,
    :code_effectif_entreprise,
    :effectif_mois,
    :effectif_annee,
    :effectif_mensuel,
    :effectif_annuel,
    :effectif_annuel_annee,
    :date_creation,
    :nom,
    :prenom

  def date_creation
    object.date_creation ? object.date_creation.to_datetime : nil
  end
end
