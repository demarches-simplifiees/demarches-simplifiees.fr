# frozen_string_literal: true

module APIEntrepriseTokenConcern
  extend ActiveSupport::Concern

  included do
    validates_associated :api_entreprise_token

    def api_entreprise_token
      t = self[:api_entreprise_token].presence || ENV['API_ENTREPRISE_KEY']

      APIEntrepriseToken.new(t)
    end

    def specific_api_entreprise_token?
      self[:api_entreprise_token].present?
    end
  end
end
