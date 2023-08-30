class Champs::ExplicationChamp < Champs::TextChamp
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end
end
