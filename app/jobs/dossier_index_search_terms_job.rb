# frozen_string_literal: true

class DossierIndexSearchTermsJob < ApplicationJob
  queue_as :low

  discard_on ActiveRecord::RecordNotFound

  def perform(dossier)
    dossier.index_search_terms
  end
end
