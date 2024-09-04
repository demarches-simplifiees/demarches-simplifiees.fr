# frozen_string_literal: true

module Types::Champs
  class RNAChampType < Types::BaseObject
    implements Types::ChampType

    class RNAType < Types::BaseObject
      field :id, String, null: false, method: :value
      field :title, String, null: true, method: :title
      field :address, Types::AddressType, null: true, method: :rna_address
    end

    field :rna, RNAType, null: true
    field :commune, Types::Champs::CommuneChampType::CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def rna_id
      object.value
    end

    def rna
      object if object.value.present?
    end
  end
end
