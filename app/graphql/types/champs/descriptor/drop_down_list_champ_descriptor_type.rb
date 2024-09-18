# frozen_string_literal: true

module Types::Champs::Descriptor
  class DropDownListChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :options, [String], "List des options d’un champ avec selection.", null: true
    field :other_option, Boolean, "La selection contien l’option \"Autre\".", null: true

    def other_option
      object.type_de_champ.drop_down_other?
    end

    def options
      object.type_de_champ.drop_down_options.reject(&:empty?)
    end
  end
end
