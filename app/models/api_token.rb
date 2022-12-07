# == Schema Information
#
# Table name: api_tokens
#
#  id                :uuid             not null, primary key
#  encrypted_token   :string           not null
#  name              :string           not null
#  version           :integer          default(3), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  administrateur_id :bigint           not null
#
class APIToken < ApplicationRecord
  include ActiveRecord::SecureToken

  belongs_to :administrateur, inverse_of: :api_tokens

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

    def find_and_verify(maybe_packed_token, administrateurs = [])
      case unpack(maybe_packed_token)
      in { plain_token:, id: } # token v3
        find_by(id:, version: 3)&.then(&ensure_valid_token(plain_token))
      in { plain_token:, administrateur_id: } # token v2
        # the migration to the APIToken model set `version: 1` for all the v1 and v2 token
        # this is the only place where we can fix the version
        where(administrateur_id:, version: 1).update_all(version: 2) # update to v2
        find_by(administrateur_id:, version: 2)&.then(&ensure_valid_token(plain_token)) ||
          find_with_administrateur_encrypted_token(plain_token, administrateurs) # before migration
      in { plain_token: } # token v1
        where(administrateur: administrateurs, version: 1).find(&ensure_valid_token(plain_token)) ||
          find_with_administrateur_encrypted_token(plain_token, administrateurs) # before migration
      end
    end

    private

    # FIXME remove after migration
    def find_with_administrateur_encrypted_token(plain_token, administrateurs)
      administrateurs
        .lazy
        .filter { _1.encrypted_token.present? }
        .map { APIToken.new(administrateur: _1, encrypted_token: _1.encrypted_token, version: 1) }
        .find(&ensure_valid_token(plain_token))
    end

    UUID_SIZE = SecureRandom.uuid.size
    def unpack(maybe_packed_token)
      case message_verifier.verified(maybe_packed_token)
      in [administrateur_id, plain_token]
        { plain_token:, administrateur_id: }
      else
        case Base64.urlsafe_decode64(maybe_packed_token).split(';')
        in [id, plain_token] if id.size == UUID_SIZE # valid format "<uuid>;<random token>"
          { plain_token:, id: }
        else
          { plain_token: maybe_packed_token }
        end
      end
    rescue
      { plain_token: maybe_packed_token }
    end

    def message_verifier
      Rails.application.message_verifier('api_v2_token')
    end

    def ensure_valid_token(plain_token)
      -> (api_token) { api_token if BCrypt::Password.new(api_token.encrypted_token) == plain_token }
    end
  end
end
