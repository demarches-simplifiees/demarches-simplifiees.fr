class EditableChamp::RepetitionRowComponent < ApplicationComponent
  def initialize(form:, champ:, row_id:, seen_at: nil)
    @form, @champ, @row_id, @seen_at = form, champ, row_id, seen_at

    @types_de_champ = champ.dossier.revision.children_of(champ.type_de_champ)
    @champs_by_stable_id_with_row = champ.dossier.champs_by_stable_id_with_row
    @row_number = champ.row_ids.find_index(row_id)
  end

  attr_reader :row_id, :row_number

  private

  def section_component
    EditableChamp::SectionComponent.new(types_de_champ: @types_de_champ, champs_by_stable_id_with_row: @champs_by_stable_id_with_row, row_id:)
  end
end
