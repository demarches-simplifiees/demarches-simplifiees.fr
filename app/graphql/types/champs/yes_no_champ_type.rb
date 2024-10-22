# frozen_string_literal: true

module Types::Champs
  class YesNoChampType < Types::BaseObject
    implements Types::ChampType

    field :value, Boolean, null: true

    def value
      if object.blank?
        nil
      else
        object.true?
      end
    end
  end
end
