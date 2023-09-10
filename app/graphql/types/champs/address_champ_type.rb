module Types::Champs
  class AddressChampType < Types::BaseObject
    implements Types::ChampType

    field :address, Types::AddressType, null: true
    field :commune, Types::Champs::CommuneChampType::CommuneType, null: true
    field :departement, Types::Champs::DepartementChampType::DepartementType, null: true

    def address
      if object.full_address?
        object.address.merge('city_code' => object.commune.fetch(:code))
      end
    end
  end
end
