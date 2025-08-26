# frozen_string_literal: true

module APIEntrepriseTokenConcern
  extend ActiveSupport::Concern

  included do
    validates_associated :api_entreprise_token

    before_save :set_api_entreprise_token_expires_at, if: :will_save_change_to_api_entreprise_token?

    def api_entreprise_token
      t = self[:api_entreprise_token].presence || ENV['API_ENTREPRISE_KEY']

      APIEntrepriseToken.new(t)
    end

    def has_api_entreprise_token?
      self[:api_entreprise_token].present?
    end

    def set_api_entreprise_token_expires_at
      self.api_entreprise_token_expires_at = api_entreprise_token.expires_at
    end
  end
end
