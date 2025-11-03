# frozen_string_literal: true

module Types::Champs::Descriptor
  class HeaderSectionChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :level, Int, null: false

    def level
      object.type_de_champ.level_for_revision(object.revision)
    end
  end
end
