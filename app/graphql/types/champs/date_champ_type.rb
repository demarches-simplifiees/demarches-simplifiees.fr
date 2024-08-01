# frozen_string_literal: true

module Types::Champs
  class DateChampType < Types::BaseObject
    implements Types::ChampType

    field :value, GraphQL::Types::ISO8601DateTime, "La valeur du champ formaté en ISO8601 (DateTime).", null: true, deprecation_reason: "Utilisez le champ `date` ou le fragment `DatetimeChamp` à la place."
    field :date, GraphQL::Types::ISO8601Date, "La valeur du champ formaté en ISO8601 (Date).", null: true

    def value
      if object.value.present?
        Time.zone.parse(object.value)
      end
    end

    def date
      if object.value.present?
        Date.parse(object.value)
      end
    end
  end
end
