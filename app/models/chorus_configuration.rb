# frozen_string_literal: true

class ChorusConfiguration
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :centre_de_cout, :simple_json, default: '{}'
  attribute :domaine_fonctionnel, :simple_json, default: '{}'
  attribute :referentiel_de_programmation, :simple_json, default: '{}'

  def self.format_centre_de_cout_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:description]} - #{api_result[:code]}"
  end

  def self.format_domaine_fonctionnel_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:label]} - #{api_result[:code]}"
  end

  def self.format_ref_programmation_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:label]} - #{api_result[:code]}"
  end

  def complete?
    [
      centre_de_cout,
      domaine_fonctionnel,
      referentiel_de_programmation,
    ].all?(&:present?)
  end
end
