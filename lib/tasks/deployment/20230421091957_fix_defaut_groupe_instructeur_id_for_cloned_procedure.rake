namespace :after_party do
  desc 'Deployment task: fix_defaut_groupe_instructeur_id_for_cloned_procedure'
  task fix_defaut_groupe_instructeur_id_for_cloned_procedure: :environment do
    procedures = Procedure
      .joins(:groupe_instructeurs)
      .where.not(parent_procedure_id: nil)
      .where("procedures.created_at > ?", Time.zone.parse("17/04/2023"))

    procedures.each do |p|
      if !p.defaut_groupe_instructeur_id.in?(p.groupe_instructeurs.map(&:id))
        wrong_groupe = p.defaut_groupe_instructeur
        new_defaut_groupe = p.groupe_instructeurs.find_by(label: p.parent_procedure.defaut_groupe_instructeur.label)
        p.update!(defaut_groupe_instructeur: new_defaut_groupe)

        p.dossiers.where(groupe_instructeur: wrong_groupe).update_all(groupe_instructeur_id: new_defaut_groupe.id)
      end
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
