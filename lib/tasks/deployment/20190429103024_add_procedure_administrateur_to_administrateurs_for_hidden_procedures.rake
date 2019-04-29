namespace :after_party do
  desc 'Deployment task: add_procedure_administrateur_to_administrateurs_for_hidden_procedures'
  task add_procedure_administrateur_to_administrateurs_for_hidden_procedures: :environment do
    rake_puts "Running deploy task: 'add_procedure_administrateur_to_administrateurs_for_hidden_procedures'"
    hidden_procedures = Procedure.unscoped.hidden.includes(:administrateurs)
    progress = ProgressReport.new(hidden_procedures.count)

    hidden_procedures.find_each do |procedure|
      deprecated_administrateur = Administrateur.find_by(id: procedure.administrateur_id)
      if deprecated_administrateur && !procedure.administrateurs.include?(deprecated_administrateur)
        procedure.administrateurs << deprecated_administrateur
      end
      progress.inc
    end

    progress.finish
    AfterParty::TaskRecord.create version: '20190429103024'
  end
end
