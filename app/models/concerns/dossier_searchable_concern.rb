module DossierSearchableConcern
  extend ActiveSupport::Concern

  included do
    before_save :update_search_terms

    def update_search_terms
      self.search_terms = [
        user&.email,
        *champs_public.flat_map(&:search_terms),
        *etablissement&.search_terms,
        individual&.nom,
        individual&.prenom
      ].compact_blank.join(' ')

      self.private_search_terms = champs_private.flat_map(&:search_terms).compact_blank.join(' ')
    end

    def update_search_terms_later
      DossierUpdateSearchTermsJob.perform_later(self)
    end
  end
end
