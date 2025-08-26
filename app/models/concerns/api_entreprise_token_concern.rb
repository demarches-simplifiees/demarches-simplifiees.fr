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

    def can_fetch_attestation_sociale?
      # https://github.com/etalab/admin_api_entreprise/blob/6f5c7ecbe94af8d5403dbff320af56e8797f3fc6/app/policies/download_attestations_policy.rb#L16
      ['attestation_sociale', 'attestation_sociale_urssaf'].any? { |r| api_entreprise_role?(r) }
    end

    def can_fetch_attestation_fiscale?
      # https://github.com/etalab/admin_api_entreprise/blob/6f5c7ecbe94af8d5403dbff320af56e8797f3fc6/app/policies/download_attestations_policy.rb#L20
      ["attestation_fiscale", "attestation_fiscale_dgfip"].any? { |r| api_entreprise_role?(r) }
    end

    def can_fetch_bilans_bdf?
      api_entreprise_role?("bilans_entreprise_bdf")
    end

    def api_entreprise_token
      self[:api_entreprise_token].presence || Rails.application.secrets.api_entreprise[:key]
    end

    def api_entreprise_token_expired_or_expires_soon?
      api_entreprise_token_expires_at && api_entreprise_token_expires_at <= SOON_TO_EXPIRE_DELAY.from_now
    end

    def has_api_entreprise_token?
      self[:api_entreprise_token].present?
    end

    def set_api_entreprise_token_expires_at
      self.api_entreprise_token_expires_at = has_api_entreprise_token? ? APIEntrepriseToken.new(api_entreprise_token).expiration : nil
    end
  end
end
