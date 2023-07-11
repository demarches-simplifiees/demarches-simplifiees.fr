class Migrations::BackfillDossierRepetitionJob < ApplicationJob
  def perform(dossier_ids)
    Dossier.where(id: dossier_ids)
      .includes(:champs, revision: :types_de_champ)
      .find_each do |dossier|
        dossier
          .revision
          .types_de_champ
          .filter do |type_de_champ|
            type_de_champ.type_champ == 'repetition' && dossier.champs.none? { _1.type_de_champ_id == type_de_champ.id }
          end
          .each do |type_de_champ|
            dossier.champs << type_de_champ.champ.build
          end
      end
  end
end
