class DossierTableExportSerializer < ActiveModel::Serializer
  attributes :id,
    :created_at,
    :updated_at,
    :archived,
    :email,
    :mandataire_social,
    :state,
    :initiated_at,
    :received_at,
    :processed_at,
    :motivation

  attribute :emails_accompagnateurs

  attributes :individual_gender,
    :individual_prenom,
    :individual_nom,
    :individual_birthdate

  def email
    object.user.try(:email)
  end

  def state
    case object.state
    when 'en_construction'
      'initiated'
    when 'en_instruction'
      'received'
    when 'accepte'
      'closed'
    when 'refuse'
      'refused'
    else
      object.state
    end
  end

  def initiated_at
    object.en_construction_at
  end

  def received_at
    object.en_instruction_at
  end

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
