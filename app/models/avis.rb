class Avis < ApplicationRecord
  belongs_to :dossier
  belongs_to :gestionnaire

  def find_email
    gestionnaire.try(:email) || email
  end
end
