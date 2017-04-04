class PrevisualisationService
  def self.destroy_all_champs dossier
    Champ.where(dossier_id: dossier.id, type_de_champ_id: dossier.procedure.types_de_champ.ids).destroy_all
  end
end
