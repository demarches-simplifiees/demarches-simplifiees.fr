# frozen_string_literal: true

module RNAChampAssociationFetchableConcern
  extend ActiveSupport::Concern

  attr_reader :association_fetch_error_key

  def fetch_association!(rna)
    self.value = rna

    return clear_association!(:blank) if rna.empty?
    return clear_association!(:invalid_rna) unless valid_champ_value?
    return clear_association!(:not_found) if (data = APIEntreprise::RNAAdapter.new(rna, procedure_id).to_params).blank?

    update_with_external_data!(data:)
  rescue APIEntreprise::API::Error, APIEntrepriseToken::TokenError => error
    if APIEntrepriseService.service_unavailable_error?(error, target: :djepva)
      clear_association!(:network_error)
    else
      Sentry.capture_exception(error, extra: { dossier_id:, rna: })
      clear_association!(nil)
    end
  end

  private

  def clear_association!(error)
    @association_fetch_error_key = error
    self.data = nil
    save(validate: false)
    false
  end
end
