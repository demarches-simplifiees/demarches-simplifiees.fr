class APIToken < ApplicationRecord
  include ActiveRecord::SecureToken

  belongs_to :administrateur, inverse_of: :api_tokens
  has_many :procedures, through: :administrateur

  before_save :check_allowed_procedure_ids_ownership

  def context
    context = { administrateur_id: administrateur_id, write_access: write_access? }

    if full_access?
      context.merge procedure_ids:
    else
      context.merge procedure_ids: procedure_ids & allowed_procedure_ids
    end
  end

  def full_access?
    allowed_procedure_ids.nil?
  end

  def procedures_to_allow
    procedures.select(:id, :libelle, :path).where.not(id: allowed_procedure_ids || []).order(:libelle)
  end

  def allowed_procedures
    if allowed_procedure_ids.present?
      procedures.select(:id, :libelle, :path).where(id: allowed_procedure_ids).order(:libelle)
    else
      []
    end
  end

  def disallow_procedure(procedure_id)
    allowed_procedure_ids = allowed_procedures.map(&:id) - [procedure_id]
    if allowed_procedure_ids.empty?
      allowed_procedure_ids = nil
    end
    update!(allowed_procedure_ids:)
  end

  # Prefix is made of the first 6 characters of the uuid base64 encoded
  # it does not leak plain token
  def prefix
    Base64.urlsafe_encode64(id).slice(0, 5)
  end

  class << self
    def generate(administrateur)
      plain_token = generate_unique_secure_token
      encrypted_token = BCrypt::Password.create(plain_token)
      api_token = create!(administrateur:, encrypted_token:, name: Date.today.strftime('Jeton d’API généré le %d/%m/%Y'))
      packed_token = Base64.urlsafe_encode64([api_token.id, plain_token].join(';'))
      [api_token, packed_token]
    end

    def find_and_verify(base64_packed_token)
      id, plain_token = Base64.urlsafe_decode64(base64_packed_token).split(';')
      find_by(id:, version: 3)&.then(&ensure_valid_token(plain_token))
    end

    private

    def ensure_valid_token(plain_token)
      -> (api_token) { api_token if BCrypt::Password.new(api_token.encrypted_token) == plain_token }
    end
  end

  private

  def check_allowed_procedure_ids_ownership
    if allowed_procedure_ids.present?
      self.allowed_procedure_ids = allowed_procedures.map(&:id)
    end
  end
end
