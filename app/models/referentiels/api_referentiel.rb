# frozen_string_literal: true

class Referentiels::APIReferentiel < Referentiel
  validates :mode, inclusion: { in: ['exact_match', 'autocomplete'] }, allow_blank: true, allow_nil: true

  before_save :name_as_url

  def last_response_body
    (last_response || {}).fetch("body") { {} }
  end

  def last_response_status
    (last_response || {}).fetch("status") { 500 }
  end

  def ready?
    configured? && last_response_status == 200
  end

  def configured?
    case type
    when "Referentiels::APIReferentiel"
      [mode, url, test_data].all?(&:present?)
    when "Referentiels::CsvReferentiel"
      false
    else
      false
    end
  end

  def name_as_url
    self.name = url
  end
end
