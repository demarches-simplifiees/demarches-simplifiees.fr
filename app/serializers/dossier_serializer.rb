class DossierSerializer < ActiveModel::Serializer
  attributes :id,
    :created_at,
    :updated_at,
    :archived,
    :email,
    :state,
    :simplified_state,
    :initiated_at,
    :received_at,
    :processed_at,
    :motivation,
    :accompagnateurs,
    :invites

  has_one :individual
  has_one :entreprise
  has_one :etablissement
  has_many :cerfa
  has_many :commentaires
  has_many :champs_private
  has_many :pieces_justificatives
  has_many :types_de_piece_justificative

  has_many :champs do
    champs = object.champs + object.quartier_prioritaires + object.cadastres
    if object.user_geometry.present?
      champs << object.user_geometry
    end
    champs
  end

  def email
    object.user&.email
  end

  def entreprise
    object.etablissement&.entreprise
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
    when 'sans_suite'
      'without_continuation'
    else
      object.state
    end
  end

  def simplified_state
    object.decorate.display_state
  end

  def initiated_at
    object.en_construction_at
  end

  def received_at
    object.en_instruction_at
  end

  def accompagnateurs
    object.followers_gestionnaires.pluck(:email)
  end

  def invites
    object.invites_gestionnaires.pluck(:email)
  end

  private

  def user_geometry(dossier)
    {
      value: dossier.geometry,
      type_de_champ: {
        id: -1,
        libelle: 'user_geometry',
        type_champ: 'user_geometry',
        order_place: -1,
        descripton: ''
      }
    }
  end
end
