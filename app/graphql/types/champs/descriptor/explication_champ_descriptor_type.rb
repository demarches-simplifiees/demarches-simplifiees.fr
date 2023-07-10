module Types::Champs::Descriptor
  class ExplicationChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :collapsible_explanation_enabled, Boolean, null: true
    field :collapsible_explanation_text, String, null: true

    def collapsible_explanation_enabled
      object.type_de_champ.collapsible_explanation_enabled?
    end

    def collapsible_explanation_text
      object.type_de_champ.collapsible_explanation_text
    end
  end
end
