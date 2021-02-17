class Entreprise < Hashie::Dash
  def read_attribute_for_serialization(attribute)
    self[attribute]
  end

  property :etablissement
  property :siren
  property :capital_social
  property :numero_tva_intracommunautaire
  property :forme_juridique, default: nil
  property :forme_juridique_code, default: nil
  property :nom_commercial
  property :raison_sociale
  property :siret_siege_social
  property :code_effectif_entreprise
  property :effectif_mois
  property :effectif_annee
  property :effectif_mensuel
  property :effectif_annuel
  property :effectif_annuel_annee
  property :date_creation
  property :nom, default: nil
  property :prenom, default: nil

  property :inline_adresse
end
