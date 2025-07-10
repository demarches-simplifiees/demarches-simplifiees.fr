# frozen_string_literal: true

class TypesDeChampEditor::DossierLinkChampComponent < TypesDeChampEditor::BaseChampComponent
  def initialize(procedures:, type_de_champ:, form:, procedure:)
    super(type_de_champ: type_de_champ, form: form, procedure: procedure)
    @procedures = procedures
  end

  def react_props
    {
      id: dom_id(@type_de_champ, :procedures),
      label: "Sélectionnez la ou les démarches concernées",
      items:,
      name: @form.field_name(:procedures, multiple: true),
      selected_keys: @type_de_champ.procedures.map { |procedure| procedure.id.to_s },
      'aria-label': "Liste des démarches",
      secondary_label: "Démarches concernées",
      no_items_label: "Aucune démarche sélectionnée"
    }
  end

  def items
    items = { '--- Démarches publiées ---' => [], '--- Démarches en test ---' => [], '--- Démarches closes ---' => [] }

    @procedures.each do |procedure|
      items["--- Démarches publiées ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "publiee"
      items["--- Démarches en test ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "brouillon"
      items["--- Démarches closes ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "close"
    end

    items
  end
end
