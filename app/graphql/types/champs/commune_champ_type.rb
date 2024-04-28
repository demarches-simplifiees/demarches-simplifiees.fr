# frozen_string_literal: true

module Types::Champs
  class CommuneChampType < Types::BaseObject
    implements Types::ChampType

    class CommuneType < Types::BaseObject
      field :name, String, "Le nom de la commune", null: false
      field :code, String, "Le code INSEE", null: false
      field :postal_code, String, "Le code postal", null: true
    end

    field :commune, CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def commune
      object if object.code?
    end

    def departement
      object.departement if object.departement?
    end
  end
end
