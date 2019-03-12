namespace :after_party do
  desc 'Deployment task: create_default_path_for_brouillons'
  task create_default_path_for_brouillons: :environment do
    puts "Running deploy task 'create_default_path_for_brouillons'"

    # Put your task implementation HERE.

    Procedure.brouillons.where(path: nil).each do |p|
      p.path = SecureRandom.uuid
      p.save
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190306172842'
  end # task :create_default_path_for_brouillons
end # namespace :after_party
