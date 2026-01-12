# frozen_string_literal: true

class Champs::QuotientFamilialChamp < Champ
  store_accessor :value_json,
    :recovered_qf_data,
    :correct_qf_data,

  def recovered_qf_data?
    value_json&.dig('recovered_qf_data') == 'true'
  end

  def not_recovered_qf_data?
    value_json&.dig('recovered_qf_data') == 'false'
  end

  def correct_qf_data?
    recovered_qf_data? && value_json&.dig('correct_qf_data') == 'true'
  end

  def incorrect_qf_data?
    recovered_qf_data? && value_json&.dig('correct_qf_data') == 'false'
  end

  def set_default_value(dossier:)
    return if dossier.for_procedure_preview?

    if !dossier.user_from_france_connect?
      self.value_json = { 'recovered_qf_data' => 'false' }
    else
      fci = dossier.user.france_connect_informations.first
      api = APIParticulier::QuotientFamilial.new(procedure.id)
      response_body = api.quotient_familial(fci)

      if response_body
        self.value_json = { 'recovered_qf_data' => 'true' }
        self.data = response_body[:data]
      else
        self.value_json = { 'recovered_qf_data' => 'false' }
      end
    end
  end
end