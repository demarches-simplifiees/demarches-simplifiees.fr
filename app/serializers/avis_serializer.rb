class AvisSerializer < ActiveModel::Serializer
  attributes :email,
    :answer,
    :introduction,
    :created_at,
    :answered_at

  def email
    object.email_to_display
  end

  def created_at
    object.created_at&.in_time_zone('UTC')
  end

  def answered_at
    object.updated_at&.in_time_zone('UTC')
  end
end
