class ChampSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :value

  has_one :type_de_champ

  def value
    if object.piece_justificative_file.attached?
      url_for(object.piece_justificative_file)
    else
      object.value
    end
  end
end
