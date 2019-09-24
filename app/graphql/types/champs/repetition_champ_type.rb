module Types::Champs
  class RepetitionChampType < Types::BaseObject
    implements Types::ChampType

    field :champs, [Types::ChampType], null: false

    def champs
      Loaders::Association.for(object.class, :champs).load(object)
    end
  end
end
