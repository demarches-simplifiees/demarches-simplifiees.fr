# frozen_string_literal: true

module Types::Champs
  class RNFChampType < Types::BaseObject
    implements Types::ChampType

    class RNFType < Types::BaseObject
      field :id, String, null: false, method: :external_id
      field :title, String, null: true, method: :title
      field :address, Types::AddressType, null: true, method: :rnf_address
    end

    field :rnf, RNFType, null: true
    field :commune, Types::Champs::CommuneChampType::CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def rnf
      object if object.external_id.present?
    end
  end
end
