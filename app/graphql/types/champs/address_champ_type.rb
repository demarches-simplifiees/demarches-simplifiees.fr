module Types::Champs
  class AddressChampType < Types::BaseObject
    implements Types::ChampType

    field :address, Types::AddressType, null: true
  end
end
