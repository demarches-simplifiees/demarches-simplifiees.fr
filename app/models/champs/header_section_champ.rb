class Champs::HeaderSectionChamp < Champ
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def section_index
    dossier
      .champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      .index(self) + 1
  end
end
