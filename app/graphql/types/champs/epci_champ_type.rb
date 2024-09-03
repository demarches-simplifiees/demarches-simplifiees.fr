# frozen_string_literal: true

module Types::Champs
  class EpciChampType < Types::BaseObject
    implements Types::ChampType

    class EpciType < Types::BaseObject
      field :name, String, null: false
      field :code, String, null: false
    end

    field :epci, EpciType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def epci
      object if object.external_id.present?
    end

    def departement
      if object.departement?
        object.departement
      end
    end
  end
end
