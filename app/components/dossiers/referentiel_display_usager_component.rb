# frozen_string_literal: true

class Dossiers::ReferentielDisplayUsagerComponent < ApplicationComponent
  delegate :type_de_champ, to: :@champ
  delegate :safe_referentiel_mapping,
           to: :type_de_champ
  attr_reader :champ
  def initialize(champ:)
    @champ = champ
  end

  def display_usager
    Hash(@champ.value_json&.with_indifferent_access)
      &.dig(:display_usager)
      &.map { |jsonpath, value| [libelle(jsonpath), format(jsonpath, value)] }
      &.reject { |_jsonpath, value| value.nil? }
  end

  private

  def libelle(jsonpath)
    safe_referentiel_mapping[jsonpath]&.dig(:libelle).presence || jsonpath
  end

  def render?
    display_usager.present?
  end

  # Formatte la valeur pour l'affichage (date, booléen, etc.)
  def format(jsonpath, value)
    mapping_type = safe_referentiel_mapping[jsonpath]&.dig(:type) || types[String]
    case mapping_type
    when types["Date"]
      if (date = DateDetectionUtils.convert_to_iso8601_date(value))
        I18n.l(Date.parse(date), format: '%d/%m/%y')
      end
    when types["DateTime"]
      if (date = DateDetectionUtils.convert_to_iso8601_datetime(value))
        I18n.l(DateTime.parse(date), format: '%d %B %Y à %R')
      end
    when types[TrueClass],
        types[FalseClass]
      case value
      when true
        I18n.t('utils.yes')
      when false
        I18n.t('utils.no')
      else
        value
      end
    when types["Liste à choix multiples"]
      Array(value).compact.join(", ")
    when types[String] && value.is_a?(String)
      value
    else
      nil
    end
  end

  def types
    Referentiels::MappingFormComponent::TYPES
  end
end
