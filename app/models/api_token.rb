class APIToken
  attr_reader :administrateur_id, :token

  def initialize(token)
    @token = token
    verify!
  end

  def administrateur?
    administrateur_id.present?
  end

  def self.message_verifier
    Rails.application.message_verifier('api_v2_token')
  end

  def self.signe(administrateur_id, token)
    message_verifier.generate([administrateur_id, token])
  end

  private

  def verify!
    @administrateur_id, @token = self.class.message_verifier.verified(@token) || [nil, @token]
  rescue
  end
end
