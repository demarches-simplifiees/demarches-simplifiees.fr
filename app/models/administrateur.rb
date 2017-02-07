class Administrateur < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :gestionnaires
  has_many :procedures

  before_save :ensure_api_token

  include CredentialsSyncableConcern

  def ensure_api_token
    if api_token.nil?
      self.api_token = generate_api_token
    end
  end

  def renew_api_token
    update_attributes(api_token: generate_api_token)
  end

  private

  def generate_api_token
    loop do
      token = SecureRandom.hex(20)
      break token unless Administrateur.find_by(api_token: token)
    end
  end

end
