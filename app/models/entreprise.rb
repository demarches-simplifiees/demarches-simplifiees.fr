class Entreprise < Hashie::Dash
  def read_attribute_for_serialization(attribute)
    self[attribute]
  end

  property :siren
  property :capital_social
  property :numero_tva_intracommunautaire
  property :forme_juridique
  property :forme_juridique_code
  property :nom_commercial
  property :raison_sociale
  property :siret_siege_social
  property :code_effectif_entreprise
  property :date_creation
  property :nom
  property :prenom

  property :inline_adresse
end
