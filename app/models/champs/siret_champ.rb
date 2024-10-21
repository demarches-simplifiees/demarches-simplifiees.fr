# frozen_string_literal: true

class Champs::SiretChamp < Champ
  include SiretChampEtablissementFetchableConcern

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end
end
