module Types::Champs
  class RepetitionChampType < Types::BaseObject
    implements Types::ChampType

    field :champs, [Types::ChampType], null: false

    def champs
      if object.champs.loaded?
        object.champs
      else
        Loaders::Association.for(object.class, :champs).load(object)
      end
    end
  end
end
