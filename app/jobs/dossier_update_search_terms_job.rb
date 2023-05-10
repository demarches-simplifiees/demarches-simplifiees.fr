class DossierUpdateSearchTermsJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.update_search_terms
    dossier.save!(touch: false)
  end
end
