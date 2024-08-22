# frozen_string_literal: true

module Types::Champs
  class CheckboxChampType < Types::BaseObject
    implements Types::ChampType

    field :value, Boolean, null: false

    def value
      case object.value
      when 'true', 'on', '1'
        true
      else
        false
      end
    end
  end
end
