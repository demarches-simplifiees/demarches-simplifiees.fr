class Champs::HeaderSectionChamp < Champ
  def level
    if parent.present?
      header_section_level_value.to_i + parent.current_section_level(dossier.revision)
    elsif header_section_level_value
      header_section_level_value.to_i
    else
      0
    end
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def libelle_with_section_index?
    libelle =~ /^\d/
  end

  def section_index
    sections.index(self) + 1
  end
end
