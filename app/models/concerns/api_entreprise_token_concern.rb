# frozen_string_literal: true

module APIEntrepriseTokenConcern
  extend ActiveSupport::Concern

  included do
    validates_associated :api_entreprise_token

    before_save :clear_api_entreprise_token_rejection, if: :will_save_change_to_api_entreprise_token?
  end

  class_methods do
    # Shared by every procedure that carries none of its own.
    def instance_api_entreprise_token = APIEntrepriseToken.new(ENV['API_ENTREPRISE_KEY'])

    def with_usable_api_entreprise_token
      procedures = where(api_entreprise_token_rejected_at: [nil, ..TOKEN_REJECTION_HOLDS_FOR.ago])
        .where.not(id: ids_with_an_unusable_api_entreprise_token)

      return procedures if instance_api_entreprise_token.usable?

      procedures.where.not(api_entreprise_token: nil)
    end

    # No SQL predicate decodes a JWT, so this one check stays in Ruby — over the
    # procedures carrying a token of their own, not over the degraded backlog.
    def ids_with_an_unusable_api_entreprise_token
      where.not(api_entreprise_token: nil)
        .pluck(:id, :api_entreprise_token)
        .filter_map { |id, token| id if !APIEntrepriseToken.new(token).usable? }
    end
  end

  def api_entreprise_token
    return APIEntrepriseToken.new(self[:api_entreprise_token]) if specific_api_entreprise_token?

    self.class.instance_api_entreprise_token
  end

  def specific_api_entreprise_token?
    self[:api_entreprise_token].present?
  end

  # Beyond that delay we try again, so a token repaired outside the form does
  # not leave the procedure blocked.
  TOKEN_REJECTION_HOLDS_FOR = 24.hours

  def api_entreprise_token_rejected?
    api_entreprise_token_rejected_at.present?
  end

  def api_entreprise_token_recently_rejected?
    api_entreprise_token_rejected_at&.after?(TOKEN_REJECTION_HOLDS_FOR.ago)
  end

  # Only called for a token of the procedure's own: nobody could renew the
  # instance one from the interface, so blocking on it would have no way out.
  def mark_api_entreprise_token_as_rejected!
    Rails.logger.error("API Entreprise rejected the token of procedure #{id}")

    update_column(:api_entreprise_token_rejected_at, Time.current)
  end

  def forget_api_entreprise_token_rejection!
    return if api_entreprise_token_rejected_at.nil?

    update_column(:api_entreprise_token_rejected_at, nil)
  end

  def api_entreprise_token_usable?
    return false if api_entreprise_token_recently_rejected?
    api_entreprise_token.usable?
  end

  private

  def clear_api_entreprise_token_rejection
    self.api_entreprise_token_rejected_at = nil
  end
end
