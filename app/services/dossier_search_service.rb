class DossierSearchService
  def self.matching_dossiers_for_gestionnaire(search_terms, gestionnaire)
    # exact id match?
    dossiers = dossier_by_exact_id_for_gestionnaire(search_terms, gestionnaire)

    # full text search
    if dossiers.empty?
      dossier = dossier_by_full_text_for_gestionnaire(search_terms, gestionnaire)
    end

    dossiers
  end

  private

  def self.dossier_by_exact_id_for_gestionnaire(search_terms, gestionnaire)
    id = search_terms.to_i
    if id != 0 && id_compatible?(id) # Sometimes gestionnaire is searching dossiers with a big number (ex: SIRET), ActiveRecord can't deal with them and throws ActiveModel::RangeError. id_compatible? prevents this.
      dossiers = dossiers_by_id(id, gestionnaire)
    end

    if dossiers.nil?
      dossiers = Dossier.none
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
    Search.new(
      gestionnaire: gestionnaire,
      query: search_terms
    ).results
  end
end
