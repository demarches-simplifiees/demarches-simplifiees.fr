# frozen_string_literal: true

class Referentiels::APIReferentiel < Referentiel
  validates :mode, inclusion: { in: ['exact_match', 'autocomplete'] }, allow_blank: true, allow_nil: true

  before_save :name_as_url

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
