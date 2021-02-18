class APIEntrepriseToken
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def roles
    decoded_token["roles"] if token.present?
  end

  def expired?
    Time.zone.now.to_i >= decoded_token["exp"] if token.present?
  end

  def role?(role)
    roles.present? && roles.include?(role)
  end

  private

  def decoded_token
    JWT.decode(token, nil, false)[0]
  end
end
