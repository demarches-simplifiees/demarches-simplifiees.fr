# frozen_string_literal: true

class EditableChamp::RepetitionRowComponent < ApplicationComponent
  def initialize(form:, dossier:, type_de_champ:, row_id:, row_number:, seen_at: nil)
    @form, @dossier, @type_de_champ, @row_id, @row_number, @seen_at = form, dossier, type_de_champ, row_id, row_number, seen_at
    @types_de_champ = dossier.revision.children_of(type_de_champ)
  end

  attr_reader :row_id, :row_number

  private

  def section_component
    EditableChamp::SectionComponent.new(dossier: @dossier, types_de_champ: @types_de_champ, row_id:)
  end
end
