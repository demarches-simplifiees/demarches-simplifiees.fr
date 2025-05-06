# frozen_string_literal: true

class EditableChamp::RepetitionRowComponent < ApplicationComponent
  def initialize(form:, dossier:, type_de_champ:, row_id:, row_number:, seen_at: nil)
    @form, @dossier, @type_de_champ, @row_id, @row_number, @seen_at = form, dossier, type_de_champ, row_id, row_number, seen_at
    @types_de_champ = dossier.revision.children_of(type_de_champ)
  end

  attr_reader :row_id, :row_number

  def has_fieldset?
    @types_de_champ.size > 1
  end

  def fieldset_legend_id
    "#{@type_de_champ.html_id}-legend"
  end

  private

  def section_component
    EditableChamp::SectionComponent.new(dossier: @dossier, types_de_champ: @types_de_champ, row_id:, row_number: has_fieldset? ? nil : @row_number, input_labelled_by_prefix: has_fieldset? ? fieldset_legend_id : nil)
  end
end
