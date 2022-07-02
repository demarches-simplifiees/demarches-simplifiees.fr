class TypesDeChampEditor::AddChampButtonComponent < ApplicationComponent
  def initialize(revision:, parent: nil, is_annotation: false)
    @revision = revision
    @parent = parent
    @is_annotation = is_annotation
  end

  private

  def annotations?
    @is_annotation
  end

  def procedure
    @revision.procedure
  end

  def button_title
    if annotations?
      "Ajouter une annotation"
    else
      "Ajouter un champ"
    end
  end

  def button_options
    {
      class: "button",
      form: { class: @parent ? "add-to-block" : "add-to-root" },
      method: :post,
      params: {
        type_de_champ: {
          libelle: champ_libelle,
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          private: annotations? ? true : nil,
          parent_id: @parent&.stable_id,
          after_stable_id: ''
        }.compact
      }
    }
  end

  def champ_libelle
    if annotations?
      "Nouvelle annotation"
    else
      "Nouveau champ"
    end
  end
end
