# frozen_string_literal: true

module Types::Champs
  class DepartementChampType < Types::BaseObject
    implements Types::ChampType

    class DepartementType < Types::BaseObject
      field :name, String, null: false
      field :code, String, null: false
    end

    field :departement, DepartementType, null: true

    def departement
      object if object.external_id.present?
    end
  end
end
