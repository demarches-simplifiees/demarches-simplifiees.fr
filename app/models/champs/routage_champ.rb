class Champs::RoutageChamp < Champs::TextChamp
  before_create :set_groupe_instructeur_id
  after_update :update_dossier_groupe_instructeur_id

  private

  # double read / method to remove
  def set_groupe_instructeur_id
    self.value = dossier.groupe_instructeur_id
  end

  def update_dossier_groupe_instructeur_id
    dossier.update_column(:groupe_instructeur_id, value)
  end
end
