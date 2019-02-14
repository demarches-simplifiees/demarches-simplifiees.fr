namespace :after_party do
  desc 'Deployment task: add_procedure_administrateur_to_administrateurs'
  task add_procedure_administrateur_to_administrateurs: :environment do
    rake_puts "Running deploy task: 'add_procedure_administrateur_to_administrateurs'"
    procedures = Procedure.includes(:administrateurs)
    progress = ProgressReport.new(procedures.count)

    procedures.find_each do |procedure|
      if !procedure.administrateurs.include?(procedure.administrateur)
        procedure.administrateurs << procedure.administrateur
      end
      progress.inc
    end

    progress.finish
    AfterParty::TaskRecord.create version: '20190214101524'
  end
end
