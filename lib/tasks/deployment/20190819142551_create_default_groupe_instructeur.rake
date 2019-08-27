namespace :after_party do
  desc 'Deployment task: create_default_groupe_instructeur'
  task create_default_groupe_instructeur: :environment do
    Procedure.find_each do |procedure|
      procedure.groupe_instructeurs.create(label: GroupeInstructeur::DEFAULT_LABEL)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190819142551'
  end
end
