module Types::Champs
  class DateChampType < Types::BaseObject
    implements Types::ChampType

    field :value, GraphQL::Types::ISO8601DateTime, null: true

    def value
      if object.value.present?
        Time.zone.parse(object.value)
      end
    end
  end
end
