# frozen_string_literal: true

module Types::Champs
  class PaysChampType < Types::BaseObject
    implements Types::ChampType

    class PaysType < Types::BaseObject
      field :name, String, null: false
      field :code, String, null: false
    end

    field :pays, PaysType, null: true

    def pays
      object if object.external_id.present?
    end
  end
end
