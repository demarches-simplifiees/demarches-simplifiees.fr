class APIToken < ApplicationRecord
  include ActiveRecord::SecureToken

  belongs_to :administrateur, inverse_of: :api_tokens

  scope :expiring_within, -> (duration) { where(expires_at: Date.today..duration.from_now) }

  scope :without_any_expiration_notice_sent_within, -> (duration) do
    where.not('(expires_at - (?::interval)) <= some(expiration_notices_sent_at)', duration.iso8601)
  end

  scope :with_a_bigger_lifetime_than, -> (duration) do
    where('? < expires_at - created_at', duration.iso8601)
  end

  scope :with_expiration_notice_to_send_for, -> (duration) do
    # example for duration = 1.month
    # take all tokens that expire in the next month
    # with a lifetime bigger than 1 month
    # without any expiration notice sent for that period
    expiring_within(duration)
      .with_a_bigger_lifetime_than(duration)
      .without_any_expiration_notice_sent_within(duration)
  end

  before_save :sanitize_targeted_procedure_ids

  def context
    {
      administrateur_id:,
      api_token_id: id,
      procedure_ids:,
      write_access:
    }
  end

  def procedure_ids
    if full_access?
      administrateur.procedures.ids
    else
      sanitized_targeted_procedure_ids
    end
  end

  def procedures
    Procedure.where(id: procedure_ids)
  end

  def full_access?
    targeted_procedure_ids.nil?
  end

  def targetable_procedures
    administrateur
      .procedures
      .where.not(id: targeted_procedure_ids)
      .select(:id, :libelle, :path)
      .order(:libelle)
  end

  def sanitized_targeted_procedure_ids
    administrateur.procedures.ids.intersection(targeted_procedure_ids || [])
  end

  # Prefix is made of the first 6 characters of the uuid base64 encoded
  # it does not leak plain token
  def prefix
    Base64.urlsafe_encode64(id).slice(0, 5)
  end

  def store_new_ip(ip)
    set = Set.new(stored_ips)
    if set.add?(IPAddr.new(ip))
      update!(stored_ips: set.to_a)
    end
  end

  def authorized_networks_for_ui
    authorized_networks.map { "#{_1.to_string}/#{_1.prefix}" }.join(', ')
  end

  def forbidden_network?(ip)
    return false if authorized_networks.blank?

    authorized_networks.none? { |range| range.include?(ip) }
  end

  def expired?
    expires_at&.past?
  end

  def eternal?
    expires_at.nil?
  end

  class << self
    def generate(administrateur)
      plain_token = generate_unique_secure_token
      encrypted_token = BCrypt::Password.create(plain_token)
      api_token = create!(administrateur:, encrypted_token:, name: Date.today.strftime('Jeton d’API généré le %d/%m/%Y'))
      bearer = BearerToken.new(api_token.id, plain_token)
      [api_token, bearer.to_string]
    end

    def authenticate(bearer_string)
      bearer = BearerToken.from_string(bearer_string)

      return if bearer.nil?

      api_token = find_by(id: bearer.api_token_id, version: 3)

      return if api_token.nil?

      BCrypt::Password.new(api_token.encrypted_token) == bearer.plain_token ? api_token : nil
    end
  end

  def last_used_at
    last_v2_authenticated_at || last_v1_authenticated_at
  end

  private

  def sanitize_targeted_procedure_ids
    if targeted_procedure_ids.present?
      write_attribute(:allowed_procedure_ids, sanitized_targeted_procedure_ids)
    end
  end

  def targeted_procedure_ids
    read_attribute(:allowed_procedure_ids)
  end

  class BearerToken < Data.define(:api_token_id, :plain_token)
    def to_string
      Base64.urlsafe_encode64([api_token_id, plain_token].join(';'))
    end

    def self.from_string(bearer_token)
      return if bearer_token.nil?

      api_token_id, plain_token = Base64.urlsafe_decode64(bearer_token).split(';')
      BearerToken.new(api_token_id, plain_token)
    rescue ArgumentError
    end
  end
end
