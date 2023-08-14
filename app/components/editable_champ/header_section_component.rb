class EditableChamp::HeaderSectionComponent < ApplicationComponent
  def initialize(form: nil, champ:, seen_at: nil)
    @champ = champ
  end

  def level
    @champ.level + 1 # skip one heading level
  end

  def libelle
    @champ.libelle
  end

  def header_section_classnames
    class_names(
      "fr-h#{level}": true,
      'header-section': @champ.dossier.auto_numbering_section_headers_for?(@champ),
      'hidden': !@champ.visible?
    )
  end

  def tag_for_depth
    if level <= 6
      "h#{level}"
    else
      "p"
    end
  end
end
