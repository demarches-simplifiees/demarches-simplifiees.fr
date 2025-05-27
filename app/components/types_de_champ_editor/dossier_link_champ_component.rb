# frozen_string_literal: true

class TypesDeChampEditor::DossierLinkChampComponent < TypesDeChampEditor::BaseChampComponent
  def initialize(procedures:, type_de_champ:, form:, procedure:)
    super(type_de_champ: type_de_champ, form: form, procedure: procedure)
    @procedures = procedures
  end

  def react_props
    {
      id: dom_id(@type_de_champ, :procedures),
      label: "Démarches concernées",
      items: @procedures.map { |procedure| ["N°#{procedure.id} - #{procedure.libelle}", procedure.id] },
      name: @form.field_name(:procedures, multiple: true)
    }
  end
end
