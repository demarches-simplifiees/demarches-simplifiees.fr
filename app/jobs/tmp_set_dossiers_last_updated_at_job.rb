class TmpSetDossiersLastUpdatedAtJob < ApplicationJob
  def perform(except)
    dossiers = Dossier.where
      .not(id: except)
      .where(last_champ_updated_at: nil)
      .includes(:champs, :avis, :commentaires)
      .limit(100)

    dossiers.find_each do |dossier|
      last_commentaire_updated_at = dossier.commentaires
        .where.not(email: OLD_CONTACT_EMAIL)
        .where.not(email: CONTACT_EMAIL)
        .maximum(:updated_at)
      last_avis_updated_at = dossier.avis.maximum(:updated_at)
      last_champ_updated_at = dossier.champs.maximum(:updated_at)
      last_champ_private_updated_at = dossier.champs_private.maximum(:updated_at)
      dossier.update_columns(
        last_commentaire_updated_at: last_commentaire_updated_at,
        last_avis_updated_at: last_avis_updated_at,
        last_champ_updated_at: last_champ_updated_at,
        last_champ_private_updated_at: last_champ_private_updated_at
      )
      except << dossier.id
    end

    if dossiers.where.not(id: except).exists?
      TmpSetDossiersLastUpdatedAtJob.perform_later(except)
    end
  end
end
