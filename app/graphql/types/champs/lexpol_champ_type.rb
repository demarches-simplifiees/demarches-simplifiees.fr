# frozen_string_literal: true

module Types::Champs
  class LexpolChampType < Types::BaseObject
    implements Types::ChampType

    field :nor, String, null: true, description: "Numéro NOR du dossier Lexpol", method: :value
    field :status, String, null: true, description: "Statut du dossier Lexpol", method: :lexpol_status
    field :dossier_url, String, null: true, description: "Lien vers le dossier Lexpol", method: :lexpol_dossier_url
  end
end
