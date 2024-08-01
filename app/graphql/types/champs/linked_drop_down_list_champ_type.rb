# frozen_string_literal: true

module Types::Champs
  class LinkedDropDownListChampType < Types::BaseObject
    implements Types::ChampType

    field :primary_value, String, null: true
    field :secondary_value, String, null: true
  end
end
