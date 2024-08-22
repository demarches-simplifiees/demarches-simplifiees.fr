# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_dossier_etablissement'
  task fix_dossier_etablissement: :environment do
    puts "Running deploy task 'fix_dossier_etablissement'"

    etablissements = Etablissement.joins(:champ).where.not(dossier_id: nil).where('etablissements.created_at > ?', 1.month.ago)
    dossiers_modif = []
    etablissements.find_each do |e|
      if e.dossier
        dossier = e.dossier
        e.update!(dossier_id: nil)
        dossier.reload.etablissement = e.reload.dup
        dossier.save!
        dossiers_modif << dossier.id
      end
    end
    puts "Nb dossiers modifiés: #{dossiers_modif.size}"
    AfterParty::TaskRecord.create version: '20200528124044'
  end
end
