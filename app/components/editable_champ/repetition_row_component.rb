# frozen_string_literal: true

class EditableChamp::RepetitionRowComponent < ApplicationComponent
  include ChampAriaLabelledbyHelper

  def initialize(form:, dossier:, champ:, row_id:, row_number:, expanded: false, seen_at: nil)
    @form, @dossier, @champ, @row_id, @row_number, @expanded, @seen_at = form, dossier, champ, row_id, row_number, expanded, seen_at
    @type_de_champ = champ.type_de_champ
    @types_de_champ = dossier.revision.children_of(@type_de_champ)
  end

  attr_reader :row_id, :row_number

  def has_fieldset?
    @types_de_champ.size > 1
  end

  private

  def section_component
    EditableChamp::SectionComponent.new(dossier: @dossier, types_de_champ: @types_de_champ, row_id:, row_number: @row_number)
  end

  def delete_button
    render NestedForms::OwnedButtonComponent.new(
      formaction: champs_repetition_path(@dossier, @type_de_champ.stable_id, row_id:),
      http_method: :delete,
      opt: {
        class: "fr-btn fr-btn--sm fr-btn--tertiary fr-icon-delete-bin-line fr-btn--icon-left utils-repetition-required-destroy-button",
        data: { turbo_confirm: t(".confirm", libelle: @type_de_champ.libelle, row_number:) },
      }
    ) do
      t(".delete", libelle: @type_de_champ.libelle, row_number:)
    end
  end
end
