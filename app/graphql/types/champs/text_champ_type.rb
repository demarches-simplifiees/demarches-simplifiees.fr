# frozen_string_literal: true

module Types::Champs
  class TextChampType < Types::BaseObject
    implements Types::ChampType

    field :value, String, null: true
  end
end
