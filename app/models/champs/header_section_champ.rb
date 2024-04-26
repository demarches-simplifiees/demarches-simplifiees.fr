class Champs::HeaderSectionChamp < Champ
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def libelle_with_section_index?
    libelle =~ /^\d/
  end

  def level
    type_de_champ.level_for_revision(dossier.revision)
  end
end
