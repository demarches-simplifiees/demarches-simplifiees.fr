# frozen_string_literal: true

class EditableChamp::HeaderSectionComponent < ApplicationComponent
  def initialize(form: nil, champ:, seen_at: nil, html_class: {})
    @champ = champ
    @html_class = html_class
  end

  def level
    @champ.level + 1 # The first title level should be a <h2>
  end

  def collapsible?
    @champ.level == 1
  end

  def libelle
    @champ.libelle
  end

  def header_section_classnames
    class_names(
      {
        "section-#{level}": true,
        'header-section': @champ.dossier.auto_numbering_section_headers_for?(@champ.type_de_champ),
        'hidden': !@champ.visible?,
      }.merge(@html_class)
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
