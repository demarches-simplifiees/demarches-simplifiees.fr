# frozen_string_literal: true

module Types::Champs::Descriptor
  class RepetitionChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :champ_descriptors, [Types::ChampDescriptorType], "Description des champs d’un bloc répétable.", null: true

    def champ_descriptors
      Loaders::Association.for(object.class, revision_types_de_champ: :type_de_champ).load(object)
    end
  end
end
