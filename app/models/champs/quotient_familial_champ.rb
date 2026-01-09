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
      # try get api part value
    end
  end
end