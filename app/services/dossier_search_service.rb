class DossierSearchService
  def self.matching_dossiers_for_gestionnaire(search_terms, gestionnaire)
    dossier_by_exact_id_for_gestionnaire(search_terms, gestionnaire)
      .presence || dossier_by_full_text_for_gestionnaire(search_terms, gestionnaire)
  end

  private

  def self.dossier_by_exact_id_for_gestionnaire(search_terms, gestionnaire)
    id = search_terms.to_i
    if id != 0 && id_compatible?(id) # Sometimes gestionnaire is searching dossiers with a big number (ex: SIRET), ActiveRecord can't deal with them and throws ActiveModel::RangeError. id_compatible? prevents this.
      dossiers_by_id(id, gestionnaire)
    else
      Dossier.none
    end
  end

  def self.dossiers_by_id(id, gestionnaire)
    (gestionnaire.dossiers.where(id: id) + gestionnaire.dossiers_from_avis.where(id: id)).uniq
  end

  def self.id_compatible?(number)
    ActiveRecord::Type::Integer.new.serialize(number)
    true
  rescue ActiveModel::RangeError
    false
  end

  def self.dossier_by_full_text_for_gestionnaire(search_terms, gestionnaire)
    ts_vector = "to_tsvector('french', search_terms || private_search_terms)"
    ts_query = "to_tsquery('french', #{Dossier.connection.quote(to_tsquery(search_terms))})"

    gestionnaire
      .dossiers
      .state_not_brouillon
      .where("#{ts_vector} @@ #{ts_query}")
      .order("COALESCE(ts_rank(#{ts_vector}, #{ts_query}), 0) DESC")
  end

  def self.to_tsquery(search_terms)
    search_terms.strip
      .gsub(/['?\\:&|!<>\(\)]/, "") # drop disallowed characters
      .split(/\s+/)           # split words
      .map { |x| "#{x}:*" }   # enable prefix matching
      .join(" & ")
  end
end
