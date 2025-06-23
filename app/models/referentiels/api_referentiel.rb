# frozen_string_literal: true

class Referentiels::APIReferentiel < Referentiel
  # An encrypted JSON object is used to store authentication data securely and flexibly.
  # This allows us to store various authentication methods in a single field.
  # Examples of authentication_data structure:
  #
  #   Basic Auth : { "username": "...", "password": "..." }
  #   OAuth2 : { "client_id": "...", "client_secret": "...", "token_url": "..." }
  #   Custom header : { "header": "X-API-Key", "value": "..." }
  #   JWT : { "header": "Authorization", "value": "Bearer ...", "jwt_options": {...} }
  encrypts :authentication_data

  enum :mode, {
    exact_match: 'exact_match',
    autocomplete: 'autocomplete'
  }

  validates :mode, inclusion: { in: modes.values }, allow_blank: true, allow_nil: true
  validate :url_allowed?

  before_save :name_as_uuid
  def self.csv_available?
    false
  end

  def self.autocomplete_available?
    false
  end

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

  def authentication_data_header
    authentication_data&.fetch('header', '')
  end

  def authentication_header_token
    authentication_data&.fetch('value', '')
  end

  def authentication_by_header_token?
    [
      authentication_method == 'header_token',
      authentication_data_header.present?,
      authentication_header_token.present?
    ].all?
  end

  private

  def name_as_uuid # should be uniq, using the url was an idea but not unique
    self.name = SecureRandom.uuid
  end

  def url_allowed?
    return if url.blank?

    uri = Addressable::URI.parse(url)
    return if uri.tld == "gouv.fr" && uri.domain != "beta.gouv.fr"
    allowed_domains = ENV.fetch('ALLOWED_API_DOMAINS_FROM_FRONTEND', '').split(',')
    if allowed_domains.none? { |allowed_domain| uri.host && allowed_domain.include?(uri.host) }
      errors.add(:url, :not_allowed, contact_email: CONTACT_EMAIL)
    end
  rescue URI::InvalidURIError, PublicSuffix::DomainInvalid
    errors.add(:url, :invalid_format)
  end
end
