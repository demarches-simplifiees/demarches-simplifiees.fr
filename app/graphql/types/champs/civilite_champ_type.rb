# frozen_string_literal: true

module Types::Champs
  class CiviliteChampType < Types::BaseObject
    implements Types::ChampType

    field :value, Types::Civilite, null: true
  end
end
