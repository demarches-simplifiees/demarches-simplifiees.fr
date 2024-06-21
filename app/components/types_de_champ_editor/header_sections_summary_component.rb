class TypesDeChampEditor::HeaderSectionsSummaryComponent < ApplicationComponent
  def initialize(procedure:, is_private:)
    @procedure = procedure
    @is_private = is_private
  end

  def header_sections
    @procedure.draft_revision
      .send(@is_private ? :revision_types_de_champ_private : :revision_types_de_champ_public)
      .filter { _1.type_de_champ.header_section? }
  end

  def href(header_section) # used by type de champ editor to anchor elements
    "##{dom_id(header_section, :type_de_champ_editor)}"
  end
end
