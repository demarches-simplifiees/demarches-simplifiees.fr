module Types::Champs
  class AddressChampType < Types::BaseObject
    implements Types::ChampType

    field :address, Types::AddressType, null: true
    field :commune, Types::Champs::CommuneChampType::CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true
  end
end
