class TypesDeChampEditor::AddChampButtonComponent < ApplicationComponent
  def initialize(procedure:, type_de_champ: nil)
    @procedure = procedure
    @type_de_champ = type_de_champ
  end

  def button_options
    {
      class: "button",
      method: :post,
      params: {
        type_de_champ: {
          private: @type_de_champ&.private?,
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          parent_id: @type_de_champ&.stable_id
        }.compact
      }
    }
  end
end
