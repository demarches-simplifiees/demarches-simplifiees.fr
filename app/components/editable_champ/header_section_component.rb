class EditableChamp::HeaderSectionComponent < ApplicationComponent
  def initialize(form:, champ:, seen_at: nil)
    @champ = champ
    @form = form
  end

  def level
    @champ.level
  end

  def libelle
    @champ.libelle
  end

  def header_section_classnames
    class_names = ["fr-h#{level}", 'header-section']

    class_names << 'header-section-counter' if @champ.dossier.auto_numbering_section_headers_for?(@champ)
    class_names
  end

  def tag_for_depth
    "h#{level + 1}"
  end
end
