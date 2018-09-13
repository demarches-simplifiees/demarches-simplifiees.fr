namespace :after_party do
  desc 'Deployment task: add_path_to_procedures'
  task add_path_to_procedures: :environment do
    puts "Running deploy task 'add_path_to_procedures'"

    Procedure.publiees.where(path: nil).find_each do |procedure|
      procedure.path = procedure.path
      procedure.save!
    end

    Procedure.archivees.where(path: nil).find_each do |procedure|
      procedure.path = procedure.path
      procedure.save!
    end

    # Update task as completed. If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20180913161001'
  end
end
