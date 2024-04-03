module DossierSearchableConcern
  extend ActiveSupport::Concern

  included do
    after_commit :update_search_terms_later

    def update_search_terms
      search_terms = [
        user&.email,
        *champs_public.flat_map(&:search_terms),
        *etablissement&.search_terms,
        individual&.nom,
        individual&.prenom
      ].compact_blank.join(' ')

      private_search_terms = champs_private.flat_map(&:search_terms).compact_blank.join(' ')

      sql = "UPDATE dossiers SET search_terms = :search_terms, private_search_terms = :private_search_terms WHERE id = :id"
      sanitized_sql = self.class.sanitize_sql_array([sql, search_terms:, private_search_terms:, id:])
      self.class.connection.execute(sanitized_sql)
    end

    def update_search_terms_later
      DossierUpdateSearchTermsJob.perform_later(self)
    end
  end
end
