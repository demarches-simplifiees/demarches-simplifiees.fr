module RNAChampAssociationFetchableConcern
  extend ActiveSupport::Concern

  attr_reader :association_fetch_error_key

  def fetch_association!(rna)
    self.value = rna

    return clear_association!(:empty) if rna.empty?
    return clear_association!(:invalid) unless valid?(:champs_public_value)
    return clear_association!(:not_found) if (data = APIEntreprise::RNAAdapter.new(rna, procedure_id).to_params).blank?

    update!(data: data)
  rescue APIEntreprise::API::Error => error
    error_key = :network_error if error.try(:network_error?) && !APIEntrepriseService.api_djepva_up?
    clear_association!(error_key)
  end

  private

  def clear_association!(error)
    @association_fetch_error_key = error
    self.data = nil
    save!
    false
  end
end
