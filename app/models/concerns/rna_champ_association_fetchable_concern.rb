module RNAChampAssociationFetchableConcern
  extend ActiveSupport::Concern

  def fetch_association!(rna)
    data = APIEntreprise::RNAAdapter.new(rna, procedure_id).to_params
    update!(data: data, value: rna)
    nil
  rescue APIEntreprise::API::Error, ActiveRecord::RecordInvalid => error
    self.data = nil
    self.value = rna
    save(validate: false)
    if error.try(:network_error?) && !APIEntrepriseService.api_up?
      :network_error
    else
      nil
    end
  end
end
