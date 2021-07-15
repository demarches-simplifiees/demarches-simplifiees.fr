module Types::Champs
  class ParapheChampType < Types::BaseObject
    implements Types::ChampType

    field :signed_by, String, null: false

    def signed_by
      object.value
    end
  end
end
