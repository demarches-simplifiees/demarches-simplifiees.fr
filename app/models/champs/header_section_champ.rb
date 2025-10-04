# frozen_string_literal: true

class Champs::HeaderSectionChamp < Champ
  attr_reader :children

  def children=(value)
    @children = value
    value.each { it.parent = self }
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def level
    type_de_champ.level_for_revision(dossier.revision)
  end
end
