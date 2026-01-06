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
end