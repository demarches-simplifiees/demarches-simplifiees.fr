class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire

  def email_to_display
    gestionnaire.try(:email) || email
  end
end
