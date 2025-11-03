# frozen_string_literal: true

module Types::Champs
  class HeaderSectionChampType < Types::BaseObject
    implements Types::ChampType

    field :level, Int, null: false
  end
end
