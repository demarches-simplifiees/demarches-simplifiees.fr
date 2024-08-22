# frozen_string_literal: true

module Types::Champs
  class DatetimeChampType < Types::BaseObject
    implements Types::ChampType

    field :datetime, GraphQL::Types::ISO8601DateTime, "La valeur du champ formaté en ISO8601 (DateTime).", null: true

    def datetime
      if object.value.present?
        Time.zone.parse(object.value)
      end
    end
  end
end
