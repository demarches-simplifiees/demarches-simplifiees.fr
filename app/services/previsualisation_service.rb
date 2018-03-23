class PrevisualisationService
  def self.delete_all_champs(dossier)
    Champ.where(dossier_id: dossier.id, type_de_champ_id: dossier.procedure.types_de_champ.ids).delete_all
  end
end
