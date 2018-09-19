namespace :after_party do
  desc 'Deployment task: add_path_to_procedures'
  task add_path_to_procedures: :environment do
    puts "Running deploy task 'add_path_to_procedures'"

    def print_procedure(procedure)
      puts "#{procedure.id}##{procedure.path} - #{procedure.errors.full_messages}"
    end

    puts "Démarches publiées :"
    Procedure.publiees.where(path: nil).find_each do |procedure|
      procedure.path = procedure.path
      if !procedure.save
        print_procedure(procedure)
      end
    end

    puts "Démarches archivées :"
    Procedure.archivees.where(path: nil).find_each do |procedure|
      if procedure.procedure_path.present?
        procedure.path = procedure.path
        if !procedure.save
          print_procedure(procedure)
        end
      end
    end

    # Update task as completed. If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20180913161001'
  end
end
