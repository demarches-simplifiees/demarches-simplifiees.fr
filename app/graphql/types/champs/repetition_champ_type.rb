module Types::Champs
  class RepetitionChampType < Types::BaseObject
    implements Types::ChampType

    class Row < Types::BaseObject
      field :champs, [Types::ChampType], null: false
    end

    field :champs, [Types::ChampType], null: false, deprecation_reason: 'Utilisez le champ `rows` à la place.'
    field :rows, [Row], null: false

    def champs
      Loaders::Association.for(object.class, champs: :type_de_champ).load(object).then do |champs|
        champs.filter(&:visible?)
      end
    end

    def rows
      Loaders::Association.for(object.class, champs: :type_de_champ).load(object).then do |champs|
        object.association(:champs).target = champs.filter(&:visible?)
        object.rows.map { { champs: _1 } }
      end
    end
  end
end
