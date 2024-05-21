class DossierIndexSearchTermsJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.index_search_terms
  end
end
