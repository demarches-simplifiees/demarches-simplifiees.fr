# frozen_string_literal: true

module Types::Champs
  class DropDownListChampType < Types::BaseObject
    implements Types::ChampType

    field :value, String, null: true
  end
end
