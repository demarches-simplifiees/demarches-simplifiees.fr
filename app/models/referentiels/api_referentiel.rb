# frozen_string_literal: true

class Referentiels::APIReferentiel < Referentiel
  enum :mode, {
    exact_match: 'exact_match',
    autocomplete: 'autocomplete'
  }
  validates :mode, inclusion: { in: modes.values }, allow_blank: true, allow_nil: true
  validate :url_allowed?

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

  def url_allowed?
    return if url.blank?

    uri = Addressable::URI.parse(url)
    return if uri.tld == "gouv.fr" && uri.domain != "beta.gouv.fr"

    whitelist = ENV.fetch('ALLOWED_API_DOMAINS_FROM_FRONTEND', '').split(',')
    if whitelist.none? { |whitelisted_url| uri.host && whitelisted_url.include?(uri.host) }
      errors.add(:url, "L'URL doit être autorisée par notre équipe, veuillez nous contacter")
    end
  rescue URI::InvalidURIError, PublicSuffix::DomainInvalid
    errors.add(:url, "L'URL est invalide")
  end
end
