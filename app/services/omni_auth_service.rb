# frozen_string_literal: true

class OmniAuthService
  def self.enabled?(provider)
    ENV["#{provider.upcase}_CLIENT_ID"].present?
  end

  PROVIDERS = ['google', 'microsoft', 'yahoo', 'sipf', 'tatou']

  def self.providers
    PROVIDERS.filter(&method(:enabled?))
  end

  def self.authorization_uri(provider)
    if provider.blank?
      raise "provider should not be nil"
    end
    client = OmniAuthClient.new(Rails.application.secrets[provider])
    scope = provider == 'yahoo' ? [:'sdpp-w'] : [:profile, :email]

    client.authorization_uri(
      scope: scope,
      state: SecureRandom.hex(16),
      nonce: SecureRandom.hex(16)
    )
  end

  def self.find_or_retrieve_user_informations(provider, code)
    fetched_fci = retrieve_user_informations(provider, code)
    FranceConnectInformation.find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) || fetched_fci
  end

  private

  def self.retrieve_user_informations(provider, code)
    if provider.blank?
      raise "provider should not be nil"
    end
    client = OmniAuthClient.new(Rails.application.secrets[provider], code)

    user_info = client.access_token!(client_auth_method: :secret)
      .userinfo!
      .raw_attributes

    FranceConnectInformation.new(
      gender: user_info[:gender],
      given_name: user_info[:given_name],
      family_name: user_info[:family_name],
      email_france_connect: user_info[:email],
      birthdate: user_info[:birthdate],
      birthplace: user_info[:birthplace],
      france_connect_particulier_id: user_info[:sub]
    )
  end
end
