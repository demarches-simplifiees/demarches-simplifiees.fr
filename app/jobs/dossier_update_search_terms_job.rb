class DossierUpdateSearchTermsJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.update_search_terms
  end
end
