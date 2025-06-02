# frozen_string_literal: true

module Types::Champs
  class CommuneDePolynesieChampType < Types::BaseObject
    implements Types::ChampType

    class PfCommuneType < Types::BaseObject
      field :name, String, "Le nom de la commune", null: false
      field :postal_code, Integer, "Le code postal", null: true
      field :island, String, "L'ile", null: true
      field :archipelago, String, "L'archipel", null: true
    end

    field :commune, PfCommuneType, null: true

    def commune
      object if object.value?
    end
  end
end
