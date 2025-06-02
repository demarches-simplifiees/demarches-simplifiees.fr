# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_champ_etablissement'
  task fix_champ_etablissement: :environment do
    puts "Running deploy task 'fix_champ_etablissement'"

    etablissements = Etablissement.joins(:champ).where.not(dossier_id: nil).where('etablissements.created_at > ?', 1.month.ago)
    dossiers_modif = []
    etablissements.find_each do |e|
      if e.dossier
        user = e.dossier.user
        dossier = e.dossier
        if user.dossiers.count == 1 && user.siret == e.champ.value
          e.update!(dossier_id: nil)
          dossier.reload.etablissement = e.reload.dup
          dossier.save!
          dossiers_modif << dossier.id
          fetch_api_entreprise_infos(dossier.etablissement.id, dossier.procedure.id, user.id)
        end
      end
    end
    puts "Nb dossiers modifiés: #{dossiers_modif.size}"
    AfterParty::TaskRecord.create version: '20200527124112'
  end

  def fetch_api_entreprise_infos(etablissement_id, procedure_id, user_id)
    [
      APIEntreprise::EntrepriseJob, APIEntreprise::AssociationJob, APIEntreprise::ExercicesJob,
      APIEntreprise::EffectifsJob, APIEntreprise::EffectifsAnnuelsJob, APIEntreprise::AttestationSocialeJob,
      APIEntreprise::BilansBdfJob
    ].each do |job|
      job.perform_later(etablissement_id, procedure_id)
    end
    APIEntreprise::AttestationFiscaleJob.perform_later(etablissement_id, procedure_id, user_id)
  end
end
