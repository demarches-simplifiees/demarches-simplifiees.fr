# frozen_string_literal: true

module Types::Champs
  class MultipleDropDownListChampType < Types::BaseObject
    implements Types::ChampType

    field :values, [String], null: false, method: :selected_options
  end
end
