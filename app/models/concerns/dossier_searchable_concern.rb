# frozen_string_literal: true

module DossierSearchableConcern
  extend ActiveSupport::Concern

  included do
    after_commit :index_search_terms_later, if: -> { previously_new_record? || user_previously_changed? || mandataire_first_name_previously_changed? || mandataire_last_name_previously_changed? }

    SEARCH_TERMS_DEBOUNCE = 5.minutes

    kredis_flag :debounce_index_search_terms_flag

    def index_search_terms
      DossierPreloader.load_one(self)

      search_terms = [
        user&.email,
        *champs_public.flat_map(&:search_terms),
        *etablissement&.search_terms,
        individual&.nom,
        individual&.prenom,
        mandataire_first_name,
        mandataire_last_name
      ].compact_blank.join(' ')

      private_search_terms = champs_private.flat_map(&:search_terms).compact_blank.join(' ')

      sql = "UPDATE dossiers SET search_terms = :search_terms, private_search_terms = :private_search_terms WHERE id = :id"
      sanitized_sql = self.class.sanitize_sql_array([sql, search_terms:, private_search_terms:, id:])
      self.class.connection.execute(sanitized_sql)
    end

    def index_search_terms_later
      return if debounce_index_search_terms_flag.marked?

      debounce_index_search_terms_flag.mark(expires_in: SEARCH_TERMS_DEBOUNCE)
      DossierIndexSearchTermsJob.set(wait: SEARCH_TERMS_DEBOUNCE).perform_later(self)
    end
  end
end
