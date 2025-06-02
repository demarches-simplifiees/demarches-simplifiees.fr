# frozen_string_literal: true

module Types::Champs
  class CodePostalDePolynesieChampType < Types::BaseObject
    implements Types::ChampType

    field :commune, Types::Champs::CommuneDePolynesieChampType::PfCommuneType, null: true

    def commune
      object if object.value?
    end
  end
end
