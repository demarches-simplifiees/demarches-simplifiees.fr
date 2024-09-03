# frozen_string_literal: true

module AvisHelper
  def safe_claimant_email(claimant)
    claimant&.email || "inconnu"
  end
end
