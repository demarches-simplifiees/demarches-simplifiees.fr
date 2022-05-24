module AvisHelper
  def safe_claimant_email(claimant)
    claimant&.email || "inconnu"
  end
end
