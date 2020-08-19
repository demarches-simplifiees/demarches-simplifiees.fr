namespace :after_party do
  desc 'Deployment task: Setting up instructeurs for ccism procedures'
  task ccism_instructeur_setup: :environment do
    puts "Running deploy task 'ccism_instructeur_setup'"

    # Put your task implementation HERE.
    ccism_instructeurs =
      ['ainea#ccism.pf', 'bella#ccism.pf', 'daniel.r#ccism.pf', 'gilles#ccism.pf', 'heitiare#ccism.pf', 'jane#ccism.pf', 'jenna#ccism.pf', 'john#ccism.pf', 'laura#ccism.pf', 'marc#ccism.pf', 'maroussia#ccism.pf', 'mike#ccism.pf', 'nelson#ccism.pf', 'patricia#ccism.pf', 'philomene#ccism.pf', 'raitea#ccism.pf', 'ruben#ccism.pf', 'sandra.w#ccism.pf', 'vanessa#ccism.pf', 'venda#ccism.pf', 'widric#ccism.pf', 'winella#ccism.pf']
    ids_to_assign =
      [
        265, # DESETI
        256, # Demande d'aide au titre du second volet
        328, # Demande d'aide au titre du second volet v2
        365, # DESETI Téléphone
        477 # Demande d’aide au titre du second volet du Fonds n
      ]
    ids_to_unassign =
      [
        220, # Demande d’Indemnité de Solidarité [IS]
        222, # Demande d’Indemnité de Solidarité [IS] (Papier / T
        312, # 2ème période [IS] Demande d’Indemnité de Solidarit
        335, # 2ème période [IS Papier / Téléphone] Demande d’Ind
        406, # DESETI Salle de projection
        428, # DESETI - Déclaration de non reprise d'activité
        460, # DESETI - Renouvellement
        461, # DESETI - Téléphone - Déclaration de reprise d'acti
        476 # Demande d’aide au titre du second volet du Fonds n
      ]
    progress = ProgressReport.new(ccism_instructeurs.size)

    puts "Processing instructeurs"
    procedures_to_assign = Procedure.where(id: ids_to_assign).to_a
    procedures_to_unassign = Procedure.where(id: ids_to_unassign).to_a

    ccism_instructeurs.each do |email|
      instructeur = Instructeur.by_email(email.tr('#', '@'))
      if instructeur
        instructeur.followed_dossiers.each do |dossier|
          instructeur.unfollow(dossier) if ids_to_unassign.include?(dossier.procedure.id)
        end
        procedures_to_assign.each { |procedure| instructeur.assign_to_procedure(procedure) }
        procedures_to_unassign.each { |procedure| instructeur.remove_from_procedure(procedure) }
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
