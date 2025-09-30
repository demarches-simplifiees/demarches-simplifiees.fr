# frozen_string_literal: true

class EditableChamp::RepetitionRowComponent < ApplicationComponent
  include ChampAriaLabelledbyHelper

  def initialize(form:, dossier:, champ:, row_id:, row_number:, seen_at: nil)
    @form, @dossier, @champ, @row_id, @row_number, @seen_at = form, dossier, champ, row_id, row_number, seen_at
    @type_de_champ = champ.type_de_champ
    @types_de_champ = dossier.revision.children_of(@type_de_champ)
  end

  attr_reader :row_id, :row_number

  def has_fieldset?
    @types_de_champ.size > 1
  end

  private

  def section_component
    EditableChamp::SectionComponent.new(dossier: @dossier, types_de_champ: @types_de_champ, row_id:)
  end
end
