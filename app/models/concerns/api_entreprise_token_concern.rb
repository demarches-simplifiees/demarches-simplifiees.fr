# frozen_string_literal: true

module APIEntrepriseTokenConcern
  extend ActiveSupport::Concern

  SOON_TO_EXPIRE_DELAY = 1.month

  included do
    validates :api_entreprise_token, jwt_token: true, allow_blank: true
    before_save :set_api_entreprise_token_expires_at, if: :will_save_change_to_api_entreprise_token?

    def api_entreprise_role?(role)
      APIEntrepriseToken.new(api_entreprise_token).role?(role)
    end

    def api_entreprise_token
      self[:api_entreprise_token].presence || Rails.application.secrets.api_entreprise[:key]
    end

    def api_entreprise_token_expired?
      APIEntrepriseToken.new(api_entreprise_token).expired?
    end

    def api_entreprise_token_expires_soon?
      api_entreprise_token_expires_at && api_entreprise_token_expires_at <= SOON_TO_EXPIRE_DELAY.from_now
    end

    def set_api_entreprise_token_expires_at
      self.api_entreprise_token_expires_at = APIEntrepriseToken.new(api_entreprise_token).expiration
    end
  end
end
