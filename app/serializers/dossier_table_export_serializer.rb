class DossierTableExportSerializer < ActiveModel::Serializer
  attributes :id,
    :created_at,
    :updated_at,
    :archived,
    :mandataire_social,
    :state,
    :initiated_at,
    :received_at,
    :processed_at

  attribute :emails_accompagnateurs

  attributes :individual_gender,
    :individual_prenom,
    :individual_nom,
    :individual_birthdate

  def individual_prenom
    object.individual.try(:prenom)
  end

  def individual_nom
    object.individual.try(:nom)
  end

  def individual_birthdate
    object.individual.try(:birthdate)
  end

  def individual_gender
    object.individual.try(:gender)
  end

  def emails_accompagnateurs
    object.followers_gestionnaires.pluck(:email).join(' ')
  end
end
